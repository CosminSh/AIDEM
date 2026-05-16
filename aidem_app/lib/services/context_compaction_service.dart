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
  final List<String>
  answeredFacts; // facts/questions the user has already answered
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
    required this.answeredFacts,
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
    answeredFacts: [],
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
        answeredFacts: List<String>.from(json['answered_facts'] ?? []),
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
    'answered_facts': answeredFacts,
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
    List<String>? answeredFacts,
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
    answeredFacts: answeredFacts ?? this.answeredFacts,
    injuryType: injuryType ?? this.injuryType,
    environment: environment ?? this.environment,
    isAlone: isAlone ?? this.isAlone,
    detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    lastUpdated: DateTime.now(),
  );

  /// Returns a concise, structured block injected before every Gemma response.
  /// The format is designed for Gemma-4-E2B-IT: compact, imperative, no prose.
  String toPromptString({String? lastAiMessage, String? currentUserMessage}) {
    final buffer = StringBuffer();
    buffer.writeln('=== SESSION STATE ===');
    buffer.writeln('LANGUAGE: Respond ONLY in $detectedLanguage.');
    buffer.writeln('STYLE: Use plain everyday words. No medical jargon.');

    if (currentUserMessage != null && currentUserMessage.trim().isNotEmpty) {
      final trimmed = currentUserMessage.trim();
      final truncated = trimmed.length > 220
          ? '${trimmed.substring(0, 220)}...'
          : trimmed;
      buffer.writeln('CURRENT USER MESSAGE: "$truncated"');
    }

    // Situation block
    if (summary.isNotEmpty) {
      buffer.writeln('INCIDENT: $incidentType | $summary');
    } else {
      buffer.writeln('INCIDENT: First contact. Assess immediately.');
    }

    if (injuryType != null) buffer.writeln('INJURY: $injuryType');
    if (environment != null) buffer.writeln('ENVIRONMENT: $environment');
    if (isAlone == true) buffer.writeln('PATIENT: Alone.');
    if (isAlone == false) buffer.writeln('PATIENT: Not alone.');
    if (hazards != 'None reported' && hazards != 'None (Confirmed)') {
      buffer.writeln('HAZARDS: $hazards');
    }
    if (confirmedResources.isNotEmpty) {
      buffer.writeln('HAS: ${confirmedResources.join(', ')}');
    }
    if (confirmedLacks.isNotEmpty) {
      buffer.writeln('LACKS: ${confirmedLacks.join(', ')}');
    }

    // Completed steps — the most critical block for preventing loops
    if (answeredFacts.isNotEmpty) {
      buffer.writeln('KNOWN FACTS / ANSWERED ALREADY (DO NOT ASK AGAIN):');
      for (final fact in answeredFacts) {
        buffer.writeln('  - $fact');
      }
    }

    if (completedSteps.isNotEmpty) {
      buffer.writeln('CARE ALREADY DONE (DO NOT TELL USER TO DO AGAIN):');
      for (final step in completedSteps) {
        buffer.writeln('  - $step');
      }
    }

    // Last AI message — hard-prevent verbatim repetition
    if (lastAiMessage != null && lastAiMessage.isNotEmpty) {
      // Truncate to avoid bloating the prompt
      final truncated = lastAiMessage.length > 200
          ? '${lastAiMessage.substring(0, 200)}...'
          : lastAiMessage;
      buffer.writeln(
        'YOUR LAST MESSAGE (DO NOT REPEAT OR PARAPHRASE): "$truncated"',
      );
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

  SituationContext _context = SituationContext.empty();
  final List<ChatMessage> _rawBuffer = [];
  String? _activeSessionId;

  SituationContext get context => _context;

  Future<void> init(String? sessionId) async {
    _activeSessionId = sessionId;
    _rawBuffer.clear();

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

  /// Updates structured context from the latest user message before the LLM
  /// answers, so the prompt already knows what the user just decided or did.
  void noteUserMessage(String userMessage, {String? previousAiMessage}) {
    _quickExtract(userMessage, previousAiMessage: previousAiMessage);
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
  String getPromptContext({
    String? lastAiMessage,
    String? currentUserMessage,
  }) => _context.toPromptString(
    lastAiMessage: lastAiMessage,
    currentUserMessage: currentUserMessage,
  );

  List<ChatMessage> getRecentMessages({int count = 8}) {
    return _rawBuffer.takeLast(count);
  }

  /// Uses Gemma to compact the raw buffer into a structured situation summary.
  /// Called by the session after enough user messages have accumulated.
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
- For "completed_steps": list actions the USER confirmed they performed. Do NOT copy actions that only the AI told them to do.
- For "resources": ONLY include things the user explicitly said they have.
- For "answered_facts": list observations/decisions the user already gave, such as "red burn, no blisters" or "patient is breathing".
- The history contains user messages only. If the user only asks "after that?" or "what next?", do NOT mark the previous AI instruction as completed.

JSON Structure:
{
  "summary": "2-sentence max: injury, current status, what was done",
  "incident_type": "burn/fall/bleed/fracture/etc",
  "injury_type": "finger burn/sprained ankle/etc",
  "urgency_level": "critical/moderate/minor",
  "is_alone": true/false/null,
  "resources": ["cool running water"],
  "lacks": ["clean bandage"],
  "completed_steps": ["cooled burn under running water for 10 minutes"],
  "answered_facts": ["burn is red with no blisters"]
}

JSON:''';

    try {
      final userOnlyHistory = _rawBuffer
          .where((m) => m.author == MessageAuthor.user)
          .toList();
      final result = await extractionCall(prompt, userOnlyHistory);
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
            (s) =>
                s.toLowerCase().contains(step.toLowerCase().split(' ').first),
          )) {
            merged.add(step);
          }
        }

        final newFacts = List<String>.from(parsed['answered_facts'] ?? []);
        final mergedFacts = List<String>.from(_context.answeredFacts);
        for (final fact in newFacts) {
          _addUnique(mergedFacts, fact);
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
          answeredFacts: mergedFacts,
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
        'no water',
        "don't have water",
        'without water',
        'no clean water',
      ],
      'bandage': [
        'no bandage',
        'no clean bandage',
        'no cloth',
        'no clean cloth',
        'no dressing',
        "don't have bandage",
        "don't have a bandage",
        "don't have cloth",
        "don't have a cloth",
        "don't have clean cloth",
        "don't have a clean cloth",
      ],
      'tourniquet': ['no tourniquet', "don't have tourniquet"],
      'signal': ['no signal', 'no service', 'no reception', "can't call"],
      'fire': ['no fire', 'no lighter', 'no matches', "can't make fire"],
      'shelter': ['no shelter', 'exposed', 'no cover'],
      'cold pack': [
        'no cold pack',
        "don't have a cold pack",
        'dont have a cold pack',
        'no ice',
        "don't have ice",
        'dont have ice',
      ],
    };

    final updatedLacks = List<String>.from(_context.confirmedLacks);
    final updatedResources = List<String>.from(_context.confirmedResources);
    final updatedSteps = List<String>.from(_context.completedSteps);
    final updatedFacts = List<String>.from(_context.answeredFacts);
    String updatedSummary = _context.summary;
    String updatedIncidentType = _context.incidentType;
    String updatedUrgency = _context.urgencyLevel;
    String? updatedInjuryType = _context.injuryType;
    String? updatedEnvironment = _context.environment;

    void addFact(String fact) => _addUnique(updatedFacts, fact);
    void addStep(String step, List<String> steps) => _addUnique(steps, step);

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
    final prevLower = previousAiMessage?.toLowerCase() ?? '';
    if (_containsAny(msg, ['forest', 'trail', 'woods'])) {
      updatedEnvironment = 'forest trail';
      addFact('Environment is a forest or trail.');
    }
    if (_containsAny(msg, ['running', 'runner', 'jogging'])) {
      addFact('User was running when the incident happened.');
    }
    if (_containsAny(msg, [
      'breathing fine',
      'breathing normally',
      'i can breathe',
      'can breathe',
      'breathing is fine',
    ])) {
      addFact('Breathing is normal.');
    }
    if (_containsAny(msg, [
      'no head',
      'did not hit my head',
      "didn't hit my head",
    ])) {
      addFact('No head impact reported.');
    }
    if ((msg == 'no' || msg == 'nope') &&
        _containsAny(prevLower, ['head', 'dizzy', 'confused'])) {
      addFact('No head injury, dizziness, or confusion reported.');
    }
    if ((msg == 'no' || msg == 'nope') && prevLower.contains('sharp pain')) {
      addFact('No sharp pain with movement.');
      if (prevLower.contains('numb')) addFact('No numbness reported.');
    }
    if (_containsAny(msg, [
      'just a bit of pain',
      'a bit of pain',
      'mild pain',
      'not sharp',
      'no sharp pain',
    ])) {
      addFact('Pain is mild and not sharp.');
    }
    if (_containsAny(msg, [
      'no clean cloth',
      "don't have a clean cloth",
      "dont have a clean cloth",
      'no bandage',
      "don't have a bandage",
      "dont have a bandage",
    ])) {
      addFact('No clean cloth or bandage available.');
      _addUnique(updatedLacks, 'bandage');
    }
    if (_containsAny(msg, [
      'no cold pack',
      "don't have a cold pack",
      "dont have a cold pack",
      'no ice',
      "don't have ice",
      'dont have ice',
    ])) {
      addFact('No cold pack or ice available.');
      _addUnique(updatedLacks, 'cold pack');
    }
    final mentionsCut =
        _containsAny(msg, [
          'cut',
          'wound',
          'sliced',
          'slice',
          'scrape',
          'bleeding',
          'blood',
        ]) ||
        _containsAny(_context.incidentType.toLowerCase(), [
          'cut',
          'wound',
          'bleed',
        ]) ||
        (_context.injuryType?.toLowerCase().contains('cut') ?? false) ||
        (_context.injuryType?.toLowerCase().contains('wound') ?? false);
    if (mentionsCut) {
      updatedIncidentType = 'cut';
      if (updatedSummary.isEmpty) {
        updatedSummary = 'Cut reported. Checking bleeding and wound depth.';
      }
      if (_containsAny(msg, ['finger', 'finder', 'thumb'])) {
        updatedInjuryType = 'finger cut';
        addFact('Cut is on a finger.');
      } else if (msg.contains('hand')) {
        updatedInjuryType = 'hand cut';
        addFact('Cut is on the hand.');
      } else {
        updatedInjuryType ??= 'cut';
      }

      final lengthMatch = RegExp(
        r'\b(\d+(?:[.,]\d+)?)\s*(cm|centimeter|centimeters|mm|millimeter|millimeters)\b',
      ).firstMatch(msg);
      if (lengthMatch != null) {
        addFact(
          'Cut length is about ${lengthMatch.group(1)} ${lengthMatch.group(2)}.',
        );
      }

      if (_containsAny(msg, ['deep', 'deesp', 'gaping', 'open cut'])) {
        addFact('Cut may be deep or gaping.');
        if (updatedUrgency == 'Unknown' || updatedUrgency == 'minor') {
          updatedUrgency = 'moderate';
        }
      }

      if (_containsAny(msg, ['bleeding', 'blood'])) {
        addFact('Cut is bleeding.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      }
      if (_containsAny(msg, [
        'fairly bad',
        'pretty bad',
        'bleeds bad',
        'bleeding bad',
        'bleeding a lot',
        'lots of blood',
        'a lot of blood',
      ])) {
        addFact('Bleeding is fairly heavy.');
        if (updatedUrgency == 'Unknown' || updatedUrgency == 'minor') {
          updatedUrgency = 'moderate';
        }
      }
      if (_containsAny(msg, ['bright red'])) {
        addFact('Blood is bright red.');
      }
      if (_containsAny(msg, ['dark red'])) {
        addFact('Blood is dark red.');
      }
      if (_containsAny(msg, ['steady flow', 'steady stream'])) {
        addFact('Bleeding is a steady flow.');
      }
      if (_containsAny(msg, [
        'spurting',
        'pulsing',
        'pumping',
        'spraying',
        'shooting out',
      ])) {
        addFact('Bleeding is spurting or pulsing.');
        updatedUrgency = 'critical';
      }
      if (_containsAny(msg, [
        'not bleeding that bad',
        'not bleeding bad',
        'not bleeding much',
        'not much bleeding',
        'not that bad',
        'bleeding a little',
        'a little blood',
        'only a little blood',
        'small amount of blood',
        'not a lot of blood',
        'not much blood',
      ])) {
        addFact('Bleeding is not heavy.');
        updatedUrgency = 'minor';
      }
      if (_containsAny(msg, [
        'almost stopped',
        'nearly stopped',
        'barely bleeding',
        'bleeding slowed',
        'bleeding is slowing',
        'is slowing',
        'it is slowing',
        'slowing down',
      ])) {
        addFact('Bleeding is almost stopped.');
        updatedUrgency = 'minor';
      }
      if (_containsAny(msg, [
        'seems to stop',
        'seems stopped',
        'seems to have stopped',
        'looks stopped',
        'looks like it stopped',
        'not bleeding anymore',
        'no bleeding',
        'bleeding stopped',
        'stopped bleeding',
        'isn\'t bleeding',
        'is not bleeding',
      ])) {
        addFact('Bleeding has stopped.');
        addStep('Bleeding controlled or stopped.', updatedSteps);
        updatedUrgency = 'minor';
        final woundLabel = updatedInjuryType.contains('knee')
            ? 'Knee wound'
            : updatedInjuryType.contains('cut')
            ? 'Cut'
            : 'Wound';
        updatedSummary = '$woundLabel reported. Bleeding has stopped.';
      }
      if ((msg == 'no' || msg == 'nope') &&
          _containsAny(prevLower, ['bleeding still heavy', 'still heavy'])) {
        addFact('Bleeding is not heavy.');
        updatedUrgency = 'minor';
      }
      if ((msg == 'yes' || msg == 'yep' || msg == 'yeah') &&
          _containsAny(prevLower, ['bleeding start to slow', 'slow down'])) {
        addFact('Bleeding is slowing.');
        updatedUrgency = 'minor';
      }
      if (_containsAny(msg, [
        'pressed',
        'pressing',
        'pressure',
        'held pressure',
      ])) {
        addStep('Applied direct pressure to the cut.', updatedSteps);
      }
    }

    final mentionsBurn =
        _containsAny(msg, ['burn', 'burned', 'burnt', 'scald']) ||
        _context.incidentType.toLowerCase().contains('burn') ||
        (_context.injuryType?.toLowerCase().contains('burn') ?? false);
    if (mentionsBurn) {
      updatedIncidentType = 'burn';
      if (updatedSummary.isEmpty) {
        updatedSummary = 'Burn reported. Waiting on severity and care details.';
      }
      if (_containsAny(msg, ['finger', 'thumb'])) {
        updatedInjuryType = 'finger burn';
        addFact('Burn is on a finger.');
      } else {
        updatedInjuryType ??= 'burn';
      }

      if (_containsAny(msg, ['first degree', 'first-degree', '1st degree'])) {
        addFact('User thinks the burn is mild/superficial.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'minor';
      }
      if (_containsAny(msg, ['dull pain', 'pain is dull']) ||
          (msg.trim() == 'dull' &&
              (previousAiMessage?.toLowerCase().contains('pain') ?? false))) {
        addFact('Dull pain.');
      }
      if (_containsAny(msg, ['sharp pain', 'pain is sharp']) ||
          (msg.trim() == 'sharp' &&
              (previousAiMessage?.toLowerCase().contains('pain') ?? false))) {
        addFact('Sharp pain.');
      }
      if (msg.contains('red')) addFact('Burn is red.');
      if (_hasNoBlisters(msg)) {
        addFact('No blisters reported.');
        if (msg.contains('red')) {
          addFact('Burn currently looks mild: red skin with no blisters.');
          updatedUrgency = 'minor';
        }
      } else if (msg.contains('blister')) {
        addFact('Blisters are present.');
        if (updatedUrgency == 'Unknown' || updatedUrgency == 'minor') {
          updatedUrgency = 'moderate';
        }
      }
      if (_containsAny(msg, [
        'white',
        'black',
        'charred',
        'numb',
        'leathery',
      ])) {
        addFact('Possible deep burn warning sign reported.');
        updatedUrgency = 'moderate';
      }
      if (_containsAny(msg, [
        'cooling it',
        'cooled it',
        'cooled the burn',
        'running water',
        'under water',
        'rinsing it',
        'rinsed it',
      ])) {
        addStep('Cooled the burn with cool running water.', updatedSteps);
        _addUnique(updatedResources, 'cool running water');
      }
      if (_containsAny(msg, ['covered it', 'covered the burn', 'dressing'])) {
        addStep(
          'Covered the burn loosely with a clean dry dressing.',
          updatedSteps,
        );
      }
    }

    final mentionsFallOrInjury =
        _containsAny(msg, [
          'fell',
          'fall',
          'stumbled',
          'tripped',
          'slipped',
          'twisted',
          'sprained',
          'hit my',
          'hurt my',
          'injured',
          'broken',
          'fracture',
        ]) ||
        _containsAny(_context.incidentType.toLowerCase(), [
          'fall',
          'injury',
          'fracture',
          'sprain',
        ]);
    if (mentionsFallOrInjury) {
      if (updatedIncidentType == 'Unknown' || updatedIncidentType == 'cut') {
        updatedIncidentType = 'injury';
      }
      if (updatedSummary.isEmpty) {
        updatedSummary =
            'Injury reported. Checking pain, movement, and warning signs.';
      }

      final noHeadImpact = _containsAny(msg, [
        'no head',
        'did not hit my head',
        "didn't hit my head",
      ]);
      final bodyPart = _bodyPartFromText(msg);
      if (bodyPart != null) {
        if (bodyPart == 'head' && noHeadImpact) {
          updatedInjuryType ??= _context.injuryType ?? 'injury';
        } else {
          updatedInjuryType = '$bodyPart injury';
          addFact('Injury is on the $bodyPart.');
          if ((updatedEnvironment == 'forest trail' ||
                  _containsAny(msg, ['running', 'runner', 'jogging'])) &&
              _containsAny(msg, ['fell', 'fall', 'stumbled', 'tripped'])) {
            updatedSummary =
                'Trail fall with $bodyPart injury. Checking bleeding, movement, and safe walk-out.';
          }
        }
      } else {
        updatedInjuryType ??= 'injury';
      }

      if (_containsAny(msg, ['swollen', 'swelling', 'puffy'])) {
        addFact('Swelling is present.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      }
      if (_containsAny(msg, ['bruised', 'bruise', 'purple'])) {
        addFact('Bruising is present.');
      }
      if (_containsAny(msg, ['deformed', 'crooked', 'bone sticking out'])) {
        addFact('Possible broken bone warning sign reported.');
        updatedUrgency = 'critical';
      }
      if (_containsAny(msg, ['numb', 'tingling', 'cannot feel'])) {
        addFact('Numbness or tingling reported.');
        if (updatedUrgency != 'critical') updatedUrgency = 'moderate';
      }
      if (_containsAny(msg, [
        "can't move",
        'cannot move',
        'can not move',
        "can't bend",
        'cannot bend',
      ])) {
        addFact('Movement is limited.');
        if (updatedUrgency != 'critical') updatedUrgency = 'moderate';
      } else if (_containsAny(msg, [
        'can move',
        'i can move',
        'can bend',
        'i can bend',
      ])) {
        addFact('Movement is possible.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'minor';
      }
      if (_containsAny(msg, [
        "can't stand",
        'cannot stand',
        "can't walk",
        'cannot walk',
        "can't put weight",
        'cannot put weight',
      ])) {
        addFact('Cannot stand or bear weight.');
        if (updatedUrgency != 'critical') updatedUrgency = 'moderate';
      } else if (_containsAny(msg, [
        'can stand',
        'can walk',
        'can put weight',
        'can pui weight',
        'can pui',
        'can bear weight',
      ])) {
        addFact('Can stand or bear weight.');
      }
      final lacksColdPack = _containsAny(msg, [
        'no cold pack',
        "don't have a cold pack",
        "dont have a cold pack",
        'no ice',
        "don't have ice",
        'dont have ice',
      ]);
      if (_containsAny(msg, ['ice', 'iced it', 'cold pack']) &&
          !lacksColdPack) {
        addStep('Applied a cold pack to the injury.', updatedSteps);
      }
      if (_containsAny(msg, ['elevated', 'raised it', 'raised my'])) {
        addStep('Elevated the injured area.', updatedSteps);
      }
      if (_containsAny(msg, ['splint', 'immobilized', 'kept it still'])) {
        addStep('Kept the injured area still.', updatedSteps);
      }
    }

    final mentionsBreathing =
        _containsAny(msg, [
          'choking',
          'choke',
          "can't breathe",
          'cannot breathe',
          'not breathing',
          'trouble breathing',
          'short of breath',
          'wheezing',
        ]) ||
        _containsAny(_context.incidentType.toLowerCase(), [
          'choking',
          'breathing',
        ]);
    if (mentionsBreathing) {
      updatedIncidentType = _containsAny(msg, ['chok'])
          ? 'choking'
          : 'breathing problem';
      if (updatedSummary.isEmpty) {
        updatedSummary =
            'Breathing problem reported. Checking breathing and ability to speak or cough.';
      }
      updatedUrgency = 'critical';
      updatedInjuryType ??= 'breathing problem';
      if (_containsAny(msg, ['can cough', 'coughing hard'])) {
        addFact('Person can cough.');
      }
      if (_containsAny(msg, [
        "can't cough",
        'cannot cough',
        "can't talk",
        'cannot talk',
        "can't speak",
        'cannot speak',
      ])) {
        addFact('Person cannot cough or speak normally.');
      }
      if (_containsAny(msg, ['breathing normally', 'can breathe'])) {
        addFact('Breathing is present.');
      }
      if (_containsAny(msg, ['not breathing', 'stopped breathing'])) {
        addFact('Person is not breathing.');
      }
    }

    final mentionsAllergy =
        _containsAny(msg, [
          'allergic',
          'allergy',
          'hives',
          'rash',
          'bee sting',
          'wasp sting',
          'stung',
          'swollen lips',
          'tongue swelling',
          'epipen',
          'epi pen',
        ]) ||
        _context.incidentType.toLowerCase().contains('allergic');
    if (mentionsAllergy) {
      updatedIncidentType = 'allergic reaction';
      updatedInjuryType ??= 'allergic reaction';
      if (updatedSummary.isEmpty) {
        updatedSummary =
            'Possible allergic reaction reported. Checking breathing and swelling.';
      }
      if (_containsAny(msg, ['hives', 'rash', 'itchy', 'itching'])) {
        addFact('Hives, rash, or itching reported.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      }
      if (_containsAny(msg, [
        'lips are swelling',
        'swollen lips',
        'tongue swelling',
        'throat swelling',
        'face swelling',
        'trouble breathing',
        "can't breathe",
        'wheezing',
      ])) {
        addFact('Allergic reaction warning sign reported.');
        updatedUrgency = 'critical';
      }
      if (_containsAny(msg, ['used epipen', 'used epi pen', 'injected epi'])) {
        addStep('Used an epinephrine auto-injector.', updatedSteps);
      }
      if (_containsAny(msg, ['have epipen', 'have epi pen'])) {
        _addUnique(updatedResources, 'epinephrine auto-injector');
      }
    }

    final mentionsPoison =
        _containsAny(msg, [
          'poison',
          'swallowed',
          'overdose',
          'too many pills',
          'chemical',
          'cleaner',
          'bleach',
          'gas fumes',
          'inhaled smoke',
        ]) ||
        _context.incidentType.toLowerCase().contains('poison');
    if (mentionsPoison) {
      updatedIncidentType = 'poisoning';
      updatedInjuryType ??= 'poisoning or exposure';
      if (updatedSummary.isEmpty) {
        updatedSummary =
            'Possible poisoning or exposure reported. Checking substance, amount, and symptoms.';
      }
      if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      if (_containsAny(msg, ['bleach', 'cleaner', 'chemical'])) {
        addFact('Chemical exposure reported.');
      }
      if (_containsAny(msg, ['too many pills', 'overdose', 'pills'])) {
        addFact('Medication or overdose concern reported.');
      }
      if (_containsAny(msg, ['vomiting', 'threw up', 'nausea'])) {
        addFact('Vomiting or nausea reported.');
      }
      if (_containsAny(msg, ['unconscious', 'passed out', 'not waking'])) {
        addFact('Person is unconscious or hard to wake.');
        updatedUrgency = 'critical';
      }
    }

    final mentionsBiteOrSting =
        _containsAny(msg, [
          'bite',
          'bit me',
          'bites',
          'sting',
          'stung',
          'snake',
          'tick',
          'dog bite',
          'cat bite',
        ]) ||
        _containsAny(_context.incidentType.toLowerCase(), ['bite', 'sting']);
    if (mentionsBiteOrSting && !mentionsAllergy) {
      updatedIncidentType = _containsAny(msg, ['sting', 'stung'])
          ? 'sting'
          : 'bite';
      updatedInjuryType ??= updatedIncidentType;
      if (updatedSummary.isEmpty) {
        updatedSummary =
            'Bite or sting reported. Checking swelling, breathing, and wound details.';
      }
      if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      if (_containsAny(msg, ['snake'])) {
        addFact('Possible snake bite reported.');
        updatedUrgency = 'critical';
      }
      if (_containsAny(msg, ['tick'])) addFact('Tick bite reported.');
      if (_containsAny(msg, ['dog'])) addFact('Dog bite reported.');
      if (_containsAny(msg, ['cat'])) addFact('Cat bite reported.');
      if (_containsAny(msg, ['swelling', 'swollen'])) {
        addFact('Swelling reported around bite or sting.');
      }
      if (_containsAny(msg, ['removed the tick', 'tick is out'])) {
        addStep('Removed the tick.', updatedSteps);
      }
    }

    final mentionsLostOrExposure =
        _containsAny(msg, [
          'lost',
          'stuck',
          'stranded',
          'no signal',
          'hypothermia',
          'too cold',
          'freezing',
          'too hot',
          'heat exhaustion',
          'dehydrated',
          'no water',
        ]) ||
        _containsAny(_context.incidentType.toLowerCase(), [
          'lost',
          'exposure',
          'dehydration',
        ]);
    if (mentionsLostOrExposure) {
      if (updatedIncidentType == 'Unknown') updatedIncidentType = 'survival';
      if (updatedSummary.isEmpty) {
        updatedSummary =
            'Survival situation reported. Checking location, safety, water, shelter, and signal.';
      }
      if (_containsAny(msg, ['lost', 'stranded', 'stuck'])) {
        addFact('User may be lost or stranded.');
      }
      if (_containsAny(msg, ['no signal', 'no service'])) {
        addFact('No phone signal reported.');
        _addUnique(updatedLacks, 'signal');
      }
      if (_containsAny(msg, ['too cold', 'freezing', 'hypothermia'])) {
        addFact('Cold exposure reported.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      }
      if (_containsAny(msg, ['too hot', 'heat exhaustion', 'overheated'])) {
        addFact('Heat exposure reported.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      }
      if (_containsAny(msg, ['dehydrated', 'thirsty', 'no water'])) {
        addFact('Water problem reported.');
        if (updatedUrgency == 'Unknown') updatedUrgency = 'moderate';
      }
    }

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
      if (prevLower.contains('assess') ||
          prevLower.contains('check') ||
          prevLower.contains('look')) {
        if (msg.split(' ').length > 2) {
          isAssessmentAnswer = true;
        }
      }
    }

    if ((isConfirmation || isAssessmentAnswer) &&
        previousAiMessage != null &&
        previousAiMessage.isNotEmpty) {
      // Extract a compact label from the AI's last instruction (first sentence)
      final firstSentence = previousAiMessage
          .split(RegExp(r'[.!?]'))
          .map((s) => s.trim())
          .firstWhere((s) => s.length > 10, orElse: () => '');

      if (firstSentence.isNotEmpty) {
        final label = firstSentence.length > 80
            ? '${firstSentence.substring(0, 80)}...'
            : firstSentence;
        final prevLower = previousAiMessage.toLowerCase();

        if (isAssessmentAnswer || _isAssessmentPrompt(prevLower)) {
          addFact(_factFromUserAnswer(userMessage, previousAiMessage));
        } else if (_isCareInstruction(prevLower) &&
            !_isNegativeOnlyAnswer(msg)) {
          addStep(_canonicalCareStep(previousAiMessage) ?? label, updatedSteps);
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
        'i fell',
        'i hit',
        'help',
        'bleeding',
        'hurt',
        'where am i',
        'i am',
      ];
      final spanishKeywords = [
        'me he',
        'tengo',
        'ayuda',
        'herida',
        'sangre',
        'duele',
        'corte',
        'pierna',
        'mano',
      ];
      final romanianKeywords = [
        'm-am',
        'am',
        'ajutor',
        'rana',
        'sange',
        'doare',
        'taiat',
        'mana',
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
      summary: updatedSummary,
      incidentType: updatedIncidentType,
      urgencyLevel: updatedUrgency,
      injuryType: updatedInjuryType,
      environment: updatedEnvironment,
      confirmedLacks: updatedLacks,
      confirmedResources: updatedResources,
      completedSteps: updatedSteps,
      answeredFacts: updatedFacts,
      hazards: updatedHazards,
      isAlone: isAlone,
      detectedLanguage: updatedLanguage,
    );
  }

  static bool _containsAny(String text, List<String> patterns) {
    return patterns.any(text.contains);
  }

  static bool _isNegativeOnlyAnswer(String msg) {
    final normalized = msg.trim().replaceAll(RegExp(r'[.!?]+$'), '');
    return normalized == 'no' ||
        normalized == 'nope' ||
        normalized == 'not yet' ||
        normalized.startsWith("i don't have") ||
        normalized.startsWith('i dont have') ||
        normalized.startsWith('no ');
  }

  static String? _bodyPartFromText(String msg) {
    const bodyParts = [
      'head',
      'neck',
      'back',
      'shoulder',
      'arm',
      'elbow',
      'wrist',
      'hand',
      'finger',
      'thumb',
      'chest',
      'belly',
      'abdomen',
      'hip',
      'leg',
      'knee',
      'ankle',
      'foot',
      'toe',
    ];

    for (final part in bodyParts) {
      if (msg.contains(part)) return part;
    }
    return null;
  }

  static void _addUnique(List<String> list, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final lower = normalized.toLowerCase();
    if (!list.any((item) => item.toLowerCase() == lower)) {
      list.add(normalized);
    }
  }

  static bool _hasNoBlisters(String msg) {
    return msg.contains('no blister') ||
        msg.contains('no blisters') ||
        msg.contains('without blister') ||
        msg.contains('without blisters') ||
        RegExp(r'\b(no|not|none)\b.{0,24}\bblisters?\b').hasMatch(msg);
  }

  static bool _isAssessmentPrompt(String previousAiMessage) {
    final lower = previousAiMessage.toLowerCase();
    return lower.contains('?') ||
        lower.contains('assess') ||
        lower.contains('check') ||
        lower.contains('look') ||
        lower.contains('examine') ||
        lower.contains('is there') ||
        lower.contains('do you see');
  }

  static bool _isCareInstruction(String previousAiMessage) {
    final lower = previousAiMessage.toLowerCase();
    if (lower.contains('?') && !lower.contains('done?')) return false;
    if (lower.startsWith('check') ||
        lower.startsWith('assess') ||
        lower.startsWith('look') ||
        lower.startsWith('examine')) {
      return false;
    }
    return _containsAny(lower, [
      'apply ',
      'cool ',
      'cover ',
      'press ',
      'wash ',
      'flush ',
      'remove ',
      'call ',
      'keep ',
      'tie ',
      'elevate ',
      'immobilize',
      'splint',
    ]);
  }

  static String? _canonicalCareStep(String previousAiMessage) {
    final lower = previousAiMessage.toLowerCase();
    if (lower.contains('burn') && lower.contains('cool')) {
      return 'Cooled the burn with cool running water.';
    }
    if (lower.contains('burn') && lower.contains('cover')) {
      return 'Covered the burn loosely with a clean dry dressing.';
    }
    if (lower.contains('pressure') || lower.contains('press')) {
      return 'Applied direct pressure.';
    }
    if (lower.contains('ice') || lower.contains('cold pack')) {
      return 'Applied a cold pack to the injury.';
    }
    if (lower.contains('elevate') || lower.contains('raise')) {
      return 'Elevated the injured area.';
    }
    if (lower.contains('splint') ||
        lower.contains('immobilize') ||
        lower.contains('keep it still')) {
      return 'Kept the injured area still.';
    }
    if (lower.contains('epipen') ||
        lower.contains('epi pen') ||
        lower.contains('epinephrine')) {
      return 'Used an epinephrine auto-injector.';
    }
    if (lower.contains('remove') && lower.contains('tick')) {
      return 'Removed the tick.';
    }
    if (lower.contains('call 911') || lower.contains('call emergency')) {
      return 'Called emergency services.';
    }
    return null;
  }

  static String _factFromUserAnswer(
    String userMessage,
    String previousAiMessage,
  ) {
    final msg = userMessage.toLowerCase();
    final prev = previousAiMessage.toLowerCase();
    final facts = <String>[];

    if ((msg == 'no' || msg == 'nope') &&
        _containsAny(prev, ['bleeding still heavy', 'still heavy'])) {
      facts.add('bleeding is not heavy');
    }
    if ((msg == 'yes' || msg == 'yep' || msg == 'yeah') &&
        _containsAny(prev, ['bleeding start to slow', 'slow down'])) {
      facts.add('bleeding is slowing');
    }
    if (_containsAny(msg, [
      'fairly bad',
      'pretty bad',
      'bleeds bad',
      'bleeding bad',
      'bleeding a lot',
      'lots of blood',
      'a lot of blood',
    ])) {
      facts.add('bleeding is fairly heavy');
    }
    if (_containsAny(msg, ['bright red'])) {
      facts.add('blood is bright red');
    }
    if (_containsAny(msg, ['dark red'])) {
      facts.add('blood is dark red');
    }
    if (_containsAny(msg, ['steady flow', 'steady stream'])) {
      facts.add('bleeding is a steady flow');
    }
    if (_containsAny(msg, [
      'spurting',
      'pulsing',
      'pumping',
      'spraying',
      'shooting out',
    ])) {
      facts.add('bleeding is spurting or pulsing');
    }
    if (_containsAny(msg, ['deep', 'deesp', 'gaping', 'open cut'])) {
      facts.add('cut may be deep or gaping');
    }
    final lengthMatch = RegExp(
      r'\b(\d+(?:[.,]\d+)?)\s*(cm|centimeter|centimeters|mm|millimeter|millimeters)\b',
    ).firstMatch(msg);
    if (lengthMatch != null) {
      facts.add(
        'cut length is about ${lengthMatch.group(1)} ${lengthMatch.group(2)}',
      );
    }
    if (_containsAny(msg, [
      'not bleeding that bad',
      'not bleeding bad',
      'not bleeding much',
      'not much bleeding',
      'not that bad',
      'bleeding a little',
      'a little blood',
      'only a little blood',
      'small amount of blood',
      'not a lot of blood',
      'not much blood',
    ])) {
      facts.add('bleeding is not heavy');
    }
    if (_containsAny(msg, [
      'almost stopped',
      'nearly stopped',
      'barely bleeding',
      'bleeding slowed',
      'bleeding is slowing',
      'is slowing',
      'it is slowing',
      'slowing down',
    ])) {
      facts.add('bleeding is almost stopped');
    }
    if (_containsAny(msg, [
      'seems to stop',
      'seems stopped',
      'seems to have stopped',
      'looks stopped',
      'looks like it stopped',
      'not bleeding anymore',
      'no bleeding',
      'bleeding stopped',
      'stopped bleeding',
      'isn\'t bleeding',
      'is not bleeding',
    ])) {
      facts.add('bleeding has stopped');
    }
    if (msg.contains('red')) facts.add('red skin');
    if (_hasNoBlisters(msg)) facts.add('no blisters');
    if (msg.contains('blister') && !_hasNoBlisters(msg)) {
      facts.add('blisters present');
    }
    if (_containsAny(msg, ['first degree', 'first-degree', '1st degree'])) {
      facts.add('user thinks it is mild/superficial');
    }
    if (_containsAny(msg, ['dull pain', 'pain is dull']) ||
        msg.trim() == 'dull') {
      facts.add('dull pain');
    }
    if (_containsAny(msg, ['sharp pain', 'pain is sharp']) ||
        msg.trim() == 'sharp') {
      facts.add('sharp pain');
    }
    if (_containsAny(msg, ['white', 'black', 'charred', 'numb', 'leathery'])) {
      facts.add('possible deep burn warning sign');
    }
    if (_containsAny(msg, ['swollen', 'swelling', 'puffy'])) {
      facts.add('swelling is present');
    }
    if (_containsAny(msg, ['bruised', 'bruise', 'purple'])) {
      facts.add('bruising is present');
    }
    if (_containsAny(msg, ['deformed', 'crooked', 'bone sticking out'])) {
      facts.add('possible broken bone warning sign');
    }
    if (_containsAny(msg, ['numb', 'tingling', 'cannot feel'])) {
      facts.add('numbness or tingling');
    }
    if (_containsAny(msg, [
      "can't move",
      'cannot move',
      'can not move',
      "can't bend",
      'cannot bend',
    ])) {
      facts.add('movement is limited');
    } else if (_containsAny(msg, [
      'can move',
      'i can move',
      'can bend',
      'i can bend',
    ])) {
      facts.add('movement is possible');
    }
    if (_containsAny(msg, [
      "can't stand",
      'cannot stand',
      "can't walk",
      'cannot walk',
      "can't put weight",
      'cannot put weight',
    ])) {
      facts.add('cannot stand or bear weight');
    } else if (_containsAny(msg, [
      'can stand',
      'can walk',
      'can put weight',
      'can bear weight',
    ])) {
      facts.add('can stand or bear weight');
    }
    if (_containsAny(msg, [
      'lips are swelling',
      'swollen lips',
      'tongue swelling',
      'throat swelling',
      'face swelling',
      'trouble breathing',
      "can't breathe",
      'wheezing',
    ])) {
      facts.add('allergic reaction warning sign');
    } else if (_containsAny(msg, ['hives', 'rash', 'itchy', 'itching'])) {
      facts.add('hives, rash, or itching');
    }
    if (_containsAny(msg, [
      "can't cough",
      'cannot cough',
      "can't talk",
      'cannot talk',
      "can't speak",
      'cannot speak',
    ])) {
      facts.add('cannot cough or speak normally');
    } else if (_containsAny(msg, ['can cough', 'coughing hard'])) {
      facts.add('can cough');
    }
    if (_containsAny(msg, ['not breathing', 'stopped breathing'])) {
      facts.add('not breathing');
    } else if (_containsAny(msg, ['breathing normally', 'can breathe'])) {
      facts.add('breathing is present');
    }
    if (_containsAny(msg, ['bleach', 'cleaner', 'chemical'])) {
      facts.add('chemical exposure');
    }
    if (_containsAny(msg, ['too many pills', 'overdose', 'pills'])) {
      facts.add('medication or overdose concern');
    }
    if (_containsAny(msg, ['vomiting', 'threw up', 'nausea'])) {
      facts.add('vomiting or nausea');
    }

    if (facts.isNotEmpty) {
      return 'User answered the previous check: ${facts.join(', ')}.';
    }

    final trimmed = userMessage.trim();
    final shortAnswer = trimmed.length > 90
        ? '${trimmed.substring(0, 90)}...'
        : trimmed;
    return 'User answered the previous question: "$shortAnswer".';
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
