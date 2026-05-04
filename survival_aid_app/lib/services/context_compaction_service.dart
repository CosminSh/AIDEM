import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Represents what we know about the user's emergency situation.
class SituationContext {
  final String summary;
  final String locationDetails; // coordinates, landmarks, trailhead
  final String incidentType;    // fall, bite, lost, medical
  final String hazards;         // weather, terrain, animals
  final String accessInfo;      // best way for rescuers to arrive
  final int patientCount;
  final String urgencyLevel;    // critical, stable, worsening
  final List<String> confirmedResources;
  final List<String> confirmedLacks;
  final String? injuryType;
  final String? environment;
  final bool? isAlone;
  final DateTime lastUpdated;

  SituationContext({
    required this.summary,
    required this.locationDetails,
    required this.incidentType,
    required this.hazards,
    required this.accessInfo,
    required this.patientCount,
    required this.urgencyLevel,
    required this.confirmedResources,
    required this.confirmedLacks,
    this.injuryType,
    this.environment,
    this.isAlone,
    required this.lastUpdated,
  });

  factory SituationContext.empty() => SituationContext(
        summary: '',
        locationDetails: 'Unknown',
        incidentType: 'Unknown',
        hazards: 'None reported',
        accessInfo: 'Unknown',
        patientCount: 1,
        urgencyLevel: 'Unknown',
        confirmedResources: [],
        confirmedLacks: [],
        isAlone: null,
        lastUpdated: DateTime.now(),
      );

  factory SituationContext.fromJson(Map<String, dynamic> json) => SituationContext(
        summary: json['summary'] ?? '',
        locationDetails: json['location_details'] ?? 'Unknown',
        incidentType: json['incident_type'] ?? 'Unknown',
        hazards: json['hazards'] ?? 'None reported',
        accessInfo: json['access_info'] ?? 'Unknown',
        patientCount: json['patient_count'] ?? 1,
        urgencyLevel: json['urgency_level'] ?? 'Unknown',
        confirmedResources: List<String>.from(json['resources'] ?? []),
        confirmedLacks: List<String>.from(json['lacks'] ?? []),
        injuryType: json['injury_type'],
        environment: json['environment'],
        isAlone: json['is_alone'],
        lastUpdated: DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'location_details': locationDetails,
        'incident_type': incidentType,
        'hazards': hazards,
        'access_info': accessInfo,
        'patient_count': patientCount,
        'urgency_level': urgencyLevel,
        'resources': confirmedResources,
        'lacks': confirmedLacks,
        'injury_type': injuryType,
        'environment': environment,
        'is_alone': isAlone,
        'last_updated': lastUpdated.toIso8601String(),
      };

  SituationContext copyWith({
    String? summary,
    String? locationDetails,
    String? incidentType,
    String? hazards,
    String? accessInfo,
    int? patientCount,
    String? urgencyLevel,
    List<String>? confirmedResources,
    List<String>? confirmedLacks,
    String? injuryType,
    String? environment,
    bool? isAlone,
  }) => SituationContext(
        summary: summary ?? this.summary,
        locationDetails: locationDetails ?? this.locationDetails,
        incidentType: incidentType ?? this.incidentType,
        hazards: hazards ?? this.hazards,
        accessInfo: accessInfo ?? this.accessInfo,
        patientCount: patientCount ?? this.patientCount,
        urgencyLevel: urgencyLevel ?? this.urgencyLevel,
        confirmedResources: confirmedResources ?? this.confirmedResources,
        confirmedLacks: confirmedLacks ?? this.confirmedLacks,
        injuryType: injuryType ?? this.injuryType,
        environment: environment ?? this.environment,
        isAlone: isAlone ?? this.isAlone,
        lastUpdated: DateTime.now(),
      );

  /// Returns a concise string for injection into a Gemma prompt.
  String toPromptString() {
    if (summary.isEmpty) return 'CONVERSATION_START';

    final buffer = StringBuffer();
    buffer.writeln('--- CONFIRMED FACTS (DO NOT RE-ASK) ---');
    buffer.writeln('Incident: $incidentType');
    buffer.writeln('Hazards: $hazards');
    buffer.writeln('Summary: $summary');
    if (confirmedResources.isNotEmpty) buffer.writeln('Resources: ${confirmedResources.join(', ')}');
    if (confirmedLacks.isNotEmpty) buffer.writeln('Lacks: ${confirmedLacks.join(', ')}');
    buffer.writeln('Status: ${isAlone == true ? 'Person is alone.' : 'Person is NOT alone.'}');
    buffer.writeln('--- END CONFIRMED FACTS ---');
    return buffer.toString();
  }

  bool get isEmpty => summary.isEmpty;
}

/// Manages the situation context — reads/writes to a JSON file on disk,
/// and uses the LLM to compact the conversation into a tight summary
/// every N messages.
class ContextCompactionService {
  static const int _compactEveryN = 4;

  SituationContext _context = SituationContext.empty();
  final List<String> _rawBuffer = []; // raw recent messages pending compaction
  int _messageCount = 0;
  String? _activeSessionId;

  SituationContext get context => _context;

  Future<void> init(String? sessionId) async {
    _activeSessionId = sessionId;
    _rawBuffer.clear();
    _messageCount = 0;
    
    if (sessionId != null) {
      await _loadFromDisk(sessionId);
    } else {
      _context = SituationContext.empty();
    }
  }

  /// Call this after every user message and AI response pair.
  Future<void> addExchange({
    required String userMessage,
    required String aiResponse,
  }) async {
    _rawBuffer.add('User: $userMessage');
    _rawBuffer.add('AI: $aiResponse');
    _messageCount++;

    // Extract quick facts from user message without LLM
    _quickExtract(userMessage);

    // Keep buffer bounded
    if (_rawBuffer.length > 20) {
      _rawBuffer.removeRange(0, _rawBuffer.length - 20);
    }
    
    if (_activeSessionId != null) {
      await _saveToDisk(_activeSessionId!);
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
    final prompt = '''Analyze this emergency conversation and extract key facts for an emergency dispatch report (ETHANE).
Return ONLY a raw JSON object. NO markdown, NO explanation, NO leading/trailing text.

EXAMPLE INPUT:
User: i fell and hit my head
AI: I'm sorry. Are you bleeding?
User: no bleeding but i feel dizzy
AI: Stay still. Are you alone?
User: yes i'm alone

EXAMPLE OUTPUT:
{
  "summary": "fell and hit head, dizzy, no bleeding, alone",
  "location_details": "Unknown",
  "incident_type": "fall",
  "hazards": "None",
  "access_info": "Unknown",
  "patient_count": 1,
  "urgency_level": "stable",
  "resources": [],
  "lacks": [],
  "injury_type": "head injury",
  "environment": "Unknown",
  "is_alone": true
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
        if (_activeSessionId != null) {
          await _saveToDisk(_activeSessionId!);
        }
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
      'shelter': ['no shelter', 'exposed', 'no test', 'no cover'],
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

    // Detect alone status from explicit user messages only — never assume
    bool? isAlone = _context.isAlone;
    if (msg.contains('alone') || msg.contains('by myself') || msg.contains('just me')) {
      isAlone = true;
    } else if (msg.contains('with me') || msg.contains('my friend') || msg.contains('my wife') ||
        msg.contains('my husband') || msg.contains('my son') || msg.contains('my daughter') ||
        msg.contains('my child') || msg.contains('we are') || msg.contains("we're")) {
      isAlone = false;
    }

    // Detect safety and basic triage status
    String updatedHazards = _context.hazards;
    if (msg.contains('safe') || msg.contains('all good') || msg.contains('no danger')) {
      updatedHazards = 'None (Confirmed)';
    }

    _context = _context.copyWith(
      confirmedLacks: updatedLacks,
      confirmedResources: updatedResources,
      hazards: updatedHazards,
      isAlone: isAlone,
    );
  }

  Future<void> _saveToDisk(String sessionId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/context_$sessionId.json');
      await file.writeAsString(jsonEncode(_context.toJson()));
    } catch (_) {}
  }

  Future<void> _loadFromDisk(String sessionId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/context_$sessionId.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _context = SituationContext.fromJson(json);
      } else {
        _context = SituationContext.empty();
      }
    } catch (_) {
      _context = SituationContext.empty();
    }
  }

  Future<void> clearSession() async {
    _context = SituationContext.empty();
    _rawBuffer.clear();
    _messageCount = 0;
    if (_activeSessionId != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/context_$_activeSessionId.json');
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}

extension _ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
