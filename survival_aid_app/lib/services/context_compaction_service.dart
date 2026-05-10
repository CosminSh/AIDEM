import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/protocol.dart';

/// Represents what we know about the user's emergency situation.
class SituationContext {
  final String summary;
  final String locationDetails; // coordinates, landmarks, trailhead
  final String incidentType; // fall, bite, lost, medical
  final String hazards; // weather, terrain, animals
  final String accessInfo; // best way for rescuers to arrive
  final int patientCount;
  final String urgencyLevel; // critical, stable, worsening
  final List<String> confirmedResources;
  final List<String> confirmedLacks;
  final List<String> completedSteps; // actions the user has confirmed doing
  final String? injuryType;
  final String? environment;
  final bool? isAlone;
  final String detectedLanguage; // English, Spanish, Romanian, etc.
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
    required this.completedSteps,
    this.injuryType,
    this.environment,
    this.isAlone,
    this.detectedLanguage = 'English',
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
    completedSteps: [],
    isAlone: null,
    detectedLanguage: 'English',
    lastUpdated: DateTime.now(),
  );

  factory SituationContext.fromJson(Map<String, dynamic> json) =>
      SituationContext(
        summary: json['summary'] ?? '',
        locationDetails: json['location_details'] ?? 'Unknown',
        incidentType: json['incident_type'] ?? 'Unknown',
        hazards: json['hazards'] ?? 'None reported',
        accessInfo: json['access_info'] ?? 'Unknown',
        patientCount: json['patient_count'] ?? 1,
        urgencyLevel: json['urgency_level'] ?? 'Unknown',
        confirmedResources: List<String>.from(json['resources'] ?? []),
        confirmedLacks: List<String>.from(json['lacks'] ?? []),
        completedSteps: List<String>.from(json['completed_steps'] ?? []),
        injuryType: json['injury_type'],
        environment: json['environment'],
        isAlone: json['is_alone'],
        detectedLanguage: json['detected_language'] ?? 'English',
        lastUpdated:
            DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
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
    'completed_steps': completedSteps,
    'injury_type': injuryType,
    'environment': environment,
    'is_alone': isAlone,
    'detected_language': detectedLanguage,
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
    List<String>? completedSteps,
    String? injuryType,
    String? environment,
    bool? isAlone,
    String? detectedLanguage,
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
    completedSteps: completedSteps ?? this.completedSteps,
    injuryType: injuryType ?? this.injuryType,
    environment: environment ?? this.environment,
    isAlone: isAlone ?? this.isAlone,
    detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    lastUpdated: DateTime.now(),
  );

  /// Returns a concise, structured block injected before every Gemma response.
  /// The format is designed for Gemma-4-E2B-IT: compact, imperative, no prose.
  String toPromptString({String? lastAiMessage}) {
    final buffer = StringBuffer();
    buffer.writeln('=== SESSION STATE ===');
    buffer.writeln('LANGUAGE: Respond ONLY in $detectedLanguage.');

    // Situation block
    if (summary.isNotEmpty) {
      buffer.writeln('INCIDENT: $incidentType | $summary');
    } else {
      buffer.writeln('INCIDENT: First contact. Assess immediately.');
    }

    if (injuryType != null) buffer.writeln('INJURY: $injuryType');
    if (isAlone == true) buffer.writeln('PATIENT: Alone.');
    if (isAlone == false) buffer.writeln('PATIENT: Not alone.');
    if (hazards != 'None reported' && hazards != 'None (Confirmed)') {
      buffer.writeln('HAZARDS: $hazards');
    }
    if (confirmedResources.isNotEmpty) {
      buffer.writeln('HAS: ${confirmedResources.join(', ')}');
    }

    // Completed steps — the most critical block for preventing loops
    if (completedSteps.isNotEmpty) {
      buffer.writeln('ALREADY ADDRESSED (NEVER REPEAT OR RE-ASK):');
      for (final step in completedSteps) {
        buffer.writeln('  ✓ $step');
      }
    }

    // Last AI message — hard-prevent verbatim repetition
    if (lastAiMessage != null && lastAiMessage.isNotEmpty) {
      // Truncate to avoid bloating the prompt
      final truncated = lastAiMessage.length > 200
          ? '${lastAiMessage.substring(0, 200)}...'
          : lastAiMessage;
      buffer.writeln('YOUR LAST MESSAGE (DO NOT REPEAT): "$truncated"');
    }

    buffer.writeln('=== END STATE ===');
    return buffer.toString();
  }

  bool get isEmpty => summary.isEmpty;
}

class ContextCompactionService {
  static const List<String> supportedLanguages = [
    'English',
    'Spanish',
    'French',
    'Romanian',
    'German',
    'Italian',
    'Portuguese',
    'Dutch',
    'Russian',
    'Ukrainian',
    'Polish',
    'Czech',
    'Hungarian',
    'Turkish',
    'Arabic',
    'Hindi',
    'Bengali',
    'Chinese',
    'Japanese',
    'Korean',
    'Vietnamese',
    'Thai',
    'Indonesian',
    'Malay',
    'Greek',
    'Swedish',
    'Danish',
    'Finnish',
    'Norwegian',
    'Hebrew',
    'Farsi',
    'Urdu',
  ];

  static const int _compactEveryN = 2;

  SituationContext _context = SituationContext.empty();
  final List<ChatMessage> _rawBuffer = [];
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

  void setLanguage(String lang) {
    _context = _context.copyWith(detectedLanguage: lang);
    if (_activeSessionId != null) {
      _saveToDisk(_activeSessionId!);
    }
  }

  /// Call this after every user message and AI response pair.
  Future<void> addExchange({
    required ChatMessage userMessage,
    required ChatMessage aiResponse,
  }) async {
    String? prevAiMessage;
    if (_rawBuffer.isNotEmpty) {
      final last = _rawBuffer.last;
      if (last.author == MessageAuthor.ai) {
        prevAiMessage = last.text;
      }
    }

    _rawBuffer.add(userMessage);
    _rawBuffer.add(aiResponse);
    _messageCount++;

    // Extract quick facts from user message without LLM
    _quickExtract(userMessage.text, previousAiMessage: prevAiMessage);

    // Keep buffer bounded — last 20 messages
    if (_rawBuffer.length > 20) {
      _rawBuffer.removeRange(0, _rawBuffer.length - 20);
    }

    if (_activeSessionId != null) {
      await _saveToDisk(_activeSessionId!);
    }
  }

  /// Builds the full prompt context string to inject before every Gemma response.
  String getPromptContext({String? lastAiMessage}) =>
      _context.toPromptString(lastAiMessage: lastAiMessage);

  List<ChatMessage> getRecentMessages({int count = 8}) {
    return _rawBuffer.takeLast(count);
  }

  /// Uses Gemma to compact the raw buffer into a structured situation summary.
  /// Called after every [_compactEveryN] messages.
  Future<void> compact(
    Future<String> Function(String prompt, List<ChatMessage> history)
    extractionCall,
  ) async {
    if (_rawBuffer.isEmpty) return;

    final prompt =
        '''You are extracting facts from an emergency conversation to update a medical report.
RULES:
- Output ONLY a raw JSON object. No markdown, no explanation.
- Values must be in ENGLISH even if the conversation is in another language.
- For "lacks": ONLY include things the user EXPLICITLY said they don't have (e.g. "I have no water"). Do NOT invent hypothetical lacks.
- For "completed_steps": list actions the user confirmed they performed (e.g. "cooled burn under running water for 10 min"). Be specific and concise.
- For "resources": ONLY include things the user explicitly said they have.

JSON Structure:
{
  "summary": "2-sentence max: injury, current status, what was done",
  "incident_type": "burn/fall/bleed/fracture/etc",
  "injury_type": "finger burn/sprained ankle/etc",
  "urgency_level": "critical/moderate/minor",
  "is_alone": true/false/null,
  "resources": ["cool running water"],
  "lacks": ["clean bandage"],
  "completed_steps": ["cooled burn under running water — effective, pain reduced"]
}

JSON:''';

    try {
      final result = await extractionCall(prompt, _rawBuffer);
      final jsonStart = result.indexOf('{');
      final jsonEnd = result.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = result.substring(jsonStart, jsonEnd + 1);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Merge extracted completed_steps with existing ones (never discard)
        final newSteps = List<String>.from(parsed['completed_steps'] ?? []);
        final merged = List<String>.from(_context.completedSteps);
        for (final step in newSteps) {
          if (!merged.any(
            (s) => s.toLowerCase().contains(step.toLowerCase().split(' ').first),
          )) {
            merged.add(step);
          }
        }

        // Only update lacks if the extraction explicitly found some.
        // If the parsed lacks list is empty, keep existing to avoid wiping confirmed lacks.
        final parsedLacks = List<String>.from(parsed['lacks'] ?? []);
        final finalLacks = parsedLacks.isNotEmpty
            ? parsedLacks
            : _context.confirmedLacks;

        _context = _context.copyWith(
          summary: (parsed['summary'] as String?)?.isNotEmpty == true
              ? parsed['summary']
              : _context.summary,
          incidentType: parsed['incident_type'] ?? _context.incidentType,
          injuryType: parsed['injury_type'] ?? _context.injuryType,
          urgencyLevel: parsed['urgency_level'] ?? _context.urgencyLevel,
          isAlone: parsed['is_alone'] ?? _context.isAlone,
          confirmedResources: List<String>.from(
            parsed['resources'] ?? _context.confirmedResources,
          ),
          confirmedLacks: finalLacks,
          completedSteps: merged,
        );

        if (_activeSessionId != null) {
          await _saveToDisk(_activeSessionId!);
        }
      }
    } catch (_) {
      // Compaction failed — keep existing context, it's not critical
    }
  }

  /// Fast regex-based fact extraction — runs without LLM on every message.
  /// [previousAiMessage] is the AI's last message; used to detect step confirmation.
  void _quickExtract(String userMessage, {String? previousAiMessage}) {
    final msg = userMessage.toLowerCase();

    // ── Lacks detection ──────────────────────────────────────────────────
    final lackPatterns = {
      'water': [
        'no water', "don't have water", 'without water', 'no clean water',
      ],
      'bandage': [
        'no bandage', 'no cloth', 'no dressing', "don't have bandage",
      ],
      'tourniquet': ['no tourniquet', "don't have tourniquet"],
      'signal': ['no signal', 'no service', 'no reception', "can't call"],
      'fire': ['no fire', 'no lighter', 'no matches', "can't make fire"],
      'shelter': ['no shelter', 'exposed', 'no cover'],
    };

    final updatedLacks = List<String>.from(_context.confirmedLacks);
    final updatedResources = List<String>.from(_context.confirmedResources);

    for (final entry in lackPatterns.entries) {
      if (entry.value.any((p) => msg.contains(p)) &&
          !updatedLacks.contains(entry.key)) {
        updatedLacks.add(entry.key);
      }
    }

    // ── Resources detection ───────────────────────────────────────────────
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

    // ── Completed steps detection ─────────────────────────────────────────
    // Detect user confirming an action was done so we can add it to completedSteps
    // and prevent the LLM from repeating that instruction.
    final updatedSteps = List<String>.from(_context.completedSteps);

    final confirmationPhrases = [
      'done', 'did that', 'ok done', 'i did', 'already did',
      "it's better", 'it is better', 'feels better', 'helped',
      'yes', 'yep', 'yeah', 'sure', 'ok', 'okay',
      'no', 'nope', 'not', 'none', // Negative answers also complete questions
      'i am rinsing', "i'm rinsing", 'rinsing it', 'cooling it',
      'applied it', 'i applied', 'covered it', 'i covered',
      'elevated it', 'i elevated', 'pressed', 'pressing it',
      'no bleeding', 'not bleeding', 'bleeding stopped', 'stopped bleeding',
    ];

    final isConfirmation = confirmationPhrases.any((p) => msg.contains(p));

    // Heuristic: If AI asked to assess/check something, and user typed >= 3 words, they probably assessed it.
    bool isAssessmentAnswer = false;
    if (previousAiMessage != null) {
      final prevLower = previousAiMessage.toLowerCase();
      if (prevLower.contains('assess') || prevLower.contains('check') || prevLower.contains('look')) {
        if (msg.split(' ').length > 2) {
          isAssessmentAnswer = true;
        }
      }
    }

    if ((isConfirmation || isAssessmentAnswer) && previousAiMessage != null && previousAiMessage.isNotEmpty) {
      // Extract a compact label from the AI's last instruction (first sentence)
      final firstSentence = previousAiMessage
          .split(RegExp(r'[.!?]'))
          .map((s) => s.trim())
          .firstWhere((s) => s.length > 10, orElse: () => '');

      if (firstSentence.isNotEmpty) {
        final label = firstSentence.length > 80
            ? '${firstSentence.substring(0, 80)}...'
            : firstSentence;

        // Avoid duplicate entries
        if (!updatedSteps.any(
          (s) => s.toLowerCase().contains(label.toLowerCase().substring(0, label.length.clamp(0, 20))),
        )) {
          updatedSteps.add(label);
        }
      }
    }

    // ── Alone detection ───────────────────────────────────────────────────
    bool? isAlone = _context.isAlone;
    if (msg.contains('alone') ||
        msg.contains('by myself') ||
        msg.contains('just me')) {
      isAlone = true;
    } else if (msg.contains('with me') ||
        msg.contains('my friend') ||
        msg.contains('my wife') ||
        msg.contains('my husband') ||
        msg.contains('my son') ||
        msg.contains('my daughter') ||
        msg.contains('my child') ||
        msg.contains('we are') ||
        msg.contains("we're")) {
      isAlone = false;
    }

    // ── Hazard detection ──────────────────────────────────────────────────
    String updatedHazards = _context.hazards;
    if (msg.contains('safe') ||
        msg.contains('all good') ||
        msg.contains('no danger') ||
        msg.contains('seguro') ||
        msg.contains('siguran')) {
      updatedHazards = 'None (Confirmed)';
    }

    // ── Language detection (heuristics) ──────────────────────────────────
    String updatedLanguage = _context.detectedLanguage;
    if (updatedLanguage == 'Auto-Detect') {
      final englishKeywords = [
        'i fell', 'i hit', 'help', 'bleeding', 'hurt', 'where am i', 'i am',
      ];
      final spanishKeywords = [
        'me he', 'tengo', 'ayuda', 'herida', 'sangre', 'duele', 'corte',
        'pierna', 'mano',
      ];
      final romanianKeywords = [
        'm-am', 'am', 'ajutor', 'rana', 'sange', 'doare', 'taiat', 'mana',
        'deget',
      ];

      if (englishKeywords.any((k) => msg.contains(k))) {
        updatedLanguage = 'English';
      } else if (spanishKeywords.any((k) => msg.contains(k))) {
        updatedLanguage = 'Spanish';
      } else if (romanianKeywords.any((k) => msg.contains(k))) {
        updatedLanguage = 'Romanian';
      }
    }

    // ── GPS detection ─────────────────────────────────────────────────────
    if (msg.contains('gps coordinates are:')) {
      final startIndex =
          msg.indexOf('gps coordinates are:') + 'gps coordinates are:'.length;
      final coords = userMessage.substring(startIndex).trim();
      _context = _context.copyWith(locationDetails: coords);
    }

    _context = _context.copyWith(
      confirmedLacks: updatedLacks,
      confirmedResources: updatedResources,
      completedSteps: updatedSteps,
      hazards: updatedHazards,
      isAlone: isAlone,
      detectedLanguage: updatedLanguage,
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
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
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
