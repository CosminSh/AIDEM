import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Represents what we know about the user's emergency situation.
class SituationContext {
  final String summary;
  final List<String> confirmedResources; // things they have
  final List<String> confirmedLacks;     // things they don't have
  final String? injuryType;
  final String? environment;
  final bool isAlone;
  final DateTime lastUpdated;

  const SituationContext({
    required this.summary,
    required this.confirmedResources,
    required this.confirmedLacks,
    this.injuryType,
    this.environment,
    required this.isAlone,
    required this.lastUpdated,
  });

  factory SituationContext.empty() => SituationContext(
        summary: '',
        confirmedResources: [],
        confirmedLacks: [],
        isAlone: false,
        lastUpdated: DateTime.now(),
      );

  factory SituationContext.fromJson(Map<String, dynamic> json) => SituationContext(
        summary: json['summary'] ?? '',
        confirmedResources: List<String>.from(json['resources'] ?? []),
        confirmedLacks: List<String>.from(json['lacks'] ?? []),
        injuryType: json['injury_type'],
        environment: json['environment'],
        isAlone: json['is_alone'] ?? false,
        lastUpdated: DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'resources': confirmedResources,
        'lacks': confirmedLacks,
        'injury_type': injuryType,
        'environment': environment,
        'is_alone': isAlone,
        'last_updated': lastUpdated.toIso8601String(),
      };

  SituationContext copyWith({
    String? summary,
    List<String>? confirmedResources,
    List<String>? confirmedLacks,
    String? injuryType,
    String? environment,
    bool? isAlone,
  }) => SituationContext(
        summary: summary ?? this.summary,
        confirmedResources: confirmedResources ?? this.confirmedResources,
        confirmedLacks: confirmedLacks ?? this.confirmedLacks,
        injuryType: injuryType ?? this.injuryType,
        environment: environment ?? this.environment,
        isAlone: isAlone ?? this.isAlone,
        lastUpdated: DateTime.now(),
      );

  /// Returns a concise string for injection into a Gemma prompt.
  String toPromptString() {
    if (summary.isEmpty) return 'No situation context yet.';

    final buffer = StringBuffer(summary);
    if (confirmedResources.isNotEmpty) {
      buffer.write('\nAvailable resources: ${confirmedResources.join(', ')}.');
    }
    if (confirmedLacks.isNotEmpty) {
      buffer.write('\nConfirmed missing: ${confirmedLacks.join(', ')}.');
    }
    if (injuryType != null) buffer.write('\nInjury type: $injuryType.');
    if (environment != null) buffer.write('\nEnvironment: $environment.');
    if (isAlone) buffer.write('\nPerson is alone.');
    return buffer.toString();
  }

  bool get isEmpty => summary.isEmpty;
}

/// Manages the situation context — reads/writes to a JSON file on disk,
/// and uses the LLM to compact the conversation into a tight summary
/// every N messages.
class ContextCompactionService {
  static const int _compactEveryN = 4;
  static const String _filename = 'session_context.json';

  SituationContext _context = SituationContext.empty();
  final List<String> _rawBuffer = []; // raw recent messages pending compaction
  int _messageCount = 0;

  SituationContext get context => _context;

  Future<void> init() async {
    await _loadFromDisk();
  }

  /// Call this after every user message and AI response pair.
  Future<void> addExchange({
    required String userMessage,
    required String aiResponse,
  }) async {
    _rawBuffer.add('User: $userMessage');
    _rawBuffer.add('Assistant: $aiResponse');
    _messageCount++;

    // Extract quick facts from user message without LLM
    _quickExtract(userMessage);

    // Keep buffer bounded
    if (_rawBuffer.length > 20) {
      _rawBuffer.removeRange(0, _rawBuffer.length - 20);
    }
  }

  /// Builds the full prompt context string to inject before every Gemma response.
  String getPromptContext() => _context.toPromptString();

  /// Returns recent raw messages for the conversation window.
  List<String> getRecentMessages({int count = 8}) {
    return _rawBuffer.takeLast(count);
  }

  /// Uses Gemma to compact the raw buffer into a structured situation summary.
  /// Called after every [_compactEveryN] messages.
  Future<void> compact(Future<String> Function(String prompt) llmCall) async {
    if (_rawBuffer.isEmpty) return;

    final conversation = _rawBuffer.join('\n');
    final prompt = '''Analyze this emergency conversation and extract key facts.
Return ONLY a JSON object with these exact keys (no markdown, no explanation):
{
  "summary": "one sentence describing what happened and current status",
  "resources": ["list", "of", "things", "person has available"],
  "lacks": ["list", "of", "things", "person said they don't have"],
  "injury_type": "wound/fracture/lost/snake_bite/burn/etc or null",
  "environment": "forest/desert/mountain/urban/etc or null",
  "is_alone": true or false
}

Conversation:
$conversation

JSON:''';

    try {
      final result = await llmCall(prompt);
      final jsonStart = result.indexOf('{');
      final jsonEnd = result.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = result.substring(jsonStart, jsonEnd + 1);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        _context = SituationContext.fromJson(parsed);
        await _saveToDisk();
      }
    } catch (_) {
      // Compaction failed — keep existing context, it's not critical
    }
  }

  /// Fast regex-based fact extraction — runs without LLM on every message.
  void _quickExtract(String userMessage) {
    final msg = userMessage.toLowerCase();

    // Detect what they lack
    final lackPatterns = {
      'water': ['no water', "don't have water", 'without water', 'no clean water'],
      'bandage': ['no bandage', 'no cloth', 'no dressing', "don't have bandage"],
      'tourniquet': ['no tourniquet', "don't have tourniquet"],
      'signal': ['no signal', 'no service', 'no reception', "can't call"],
      'fire': ['no fire', 'no lighter', 'no matches', "can't make fire"],
      'shelter': ['no shelter', 'exposed', 'no tent', 'no cover'],
    };

    final updatedLacks = List<String>.from(_context.confirmedLacks);
    final updatedResources = List<String>.from(_context.confirmedResources);

    for (final entry in lackPatterns.entries) {
      if (entry.value.any((p) => msg.contains(p)) &&
          !updatedLacks.contains(entry.key)) {
        updatedLacks.add(entry.key);
      }
    }

    // Detect what they have
    final hasPatterns = {
      'tourniquet': ['have tourniquet', 'have a tourniquet', 'got tourniquet'],
      'first aid kit': ['have kit', 'have first aid', 'have a kit'],
      'water': ['have water', 'found water', 'have some water'],
      'phone': ['have phone', 'have my phone'],
    };

    for (final entry in hasPatterns.entries) {
      if (entry.value.any((p) => msg.contains(p)) &&
          !updatedResources.contains(entry.key)) {
        updatedResources.add(entry.key);
      }
    }

    // Detect alone
    bool isAlone = _context.isAlone;
    if (msg.contains('alone') || msg.contains('by myself') || msg.contains('just me')) {
      isAlone = true;
    }

    _context = _context.copyWith(
      confirmedLacks: updatedLacks,
      confirmedResources: updatedResources,
      isAlone: isAlone,
    );
  }

  Future<void> _saveToDisk() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_filename');
      await file.writeAsString(jsonEncode(_context.toJson()));
    } catch (_) {}
  }

  Future<void> _loadFromDisk() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_filename');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _context = SituationContext.fromJson(json);
      }
    } catch (_) {
      _context = SituationContext.empty();
    }
  }

  Future<void> clearSession() async {
    _context = SituationContext.empty();
    _rawBuffer.clear();
    _messageCount = 0;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_filename');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

extension _ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
