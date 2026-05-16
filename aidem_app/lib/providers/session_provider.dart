import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/demo_scenario.dart';
import '../models/protocol.dart';
import 'global_providers.dart';
import '../services/conversation_guard_service.dart';
import '../services/gps_service.dart';
import '../services/session_persistence_service.dart';

class SessionState {
  final ProtocolNode? currentNode;
  final List<ChatMessage> chatHistory;
  final bool isEmergencyActive;
  final bool isPracticeMode;
  final bool isProtocolLoaded;
  final bool isLlmTyping;
  final String streamingBuffer;
  final String? currentSessionId;
  final String situationSummary;
  final List<GpsCoordinates> locationHistory;
  final List<PersistedSession> sessionHistory;

  SessionState({
    this.currentNode,
    required this.chatHistory,
    required this.isEmergencyActive,
    required this.isPracticeMode,
    this.isProtocolLoaded = false,
    this.isLlmTyping = false,
    this.streamingBuffer = '',
    this.currentSessionId,
    required this.situationSummary,
    this.locationHistory = const [],
    this.sessionHistory = const [],
  });

  SessionState copyWith({
    ProtocolNode? currentNode,
    List<ChatMessage>? chatHistory,
    bool? isEmergencyActive,
    bool? isPracticeMode,
    bool? isProtocolLoaded,
    bool? isLlmTyping,
    String? streamingBuffer,
    String? currentSessionId,
    String? situationSummary,
    List<GpsCoordinates>? locationHistory,
    List<PersistedSession>? sessionHistory,
    bool clearCurrentNode = false,
    bool clearSessionId = false,
  }) {
    return SessionState(
      currentNode: clearCurrentNode ? null : (currentNode ?? this.currentNode),
      chatHistory: chatHistory ?? this.chatHistory,
      isEmergencyActive: isEmergencyActive ?? this.isEmergencyActive,
      isPracticeMode: isPracticeMode ?? this.isPracticeMode,
      isProtocolLoaded: isProtocolLoaded ?? this.isProtocolLoaded,
      isLlmTyping: isLlmTyping ?? this.isLlmTyping,
      streamingBuffer: streamingBuffer ?? this.streamingBuffer,
      currentSessionId: clearSessionId
          ? null
          : (currentSessionId ?? this.currentSessionId),
      situationSummary: situationSummary ?? this.situationSummary,
      locationHistory: locationHistory ?? this.locationHistory,
      sessionHistory: sessionHistory ?? this.sessionHistory,
    );
  }
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    return SessionState(
      currentNode: null,
      chatHistory: [],
      isEmergencyActive: false,
      isPracticeMode: false,
      situationSummary: '',
    );
  }

  Future<void> initialize() async {
    try {
      final protocolService = ref.read(protocolServiceProvider);
      await protocolService.loadProtocol();

      // Also initialize the LLM
      final llm = ref.read(llmServiceProvider.notifier);
      await llm.init();

      await refreshHistory();
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      state = state.copyWith(isProtocolLoaded: true);
    }
  }

  Future<void> refreshHistory() async {
    final persistence = ref.read(sessionPersistenceServiceProvider);
    final history = await persistence.getAllSessions();
    state = state.copyWith(sessionHistory: history);
  }

  void setLanguage(String lang) {
    ref.read(contextCompactionServiceProvider).setLanguage(lang);
  }

  void _persist() {
    if (state.currentSessionId == null) return;

    final persistence = ref.read(sessionPersistenceServiceProvider);
    persistence.saveSession(
      PersistedSession(
        id: state.currentSessionId!,
        chatHistory: state.chatHistory,
        currentNodeId: state.currentNode?.id,
        isEmergencyActive: state.isEmergencyActive,
        isPracticeMode: state.isPracticeMode,
        situationSummary: state.situationSummary,
        locationHistory: state.locationHistory,
        lastUpdated: DateTime.now(),
      ),
    );
    refreshHistory();
  }

  Future<void> startEmergency() async {
    await ref.read(llmServiceProvider.notifier).init();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    await ref.read(contextCompactionServiceProvider).init(newId);

    _initSession(practice: false, sessionId: newId);
    _persist();
  }

  Future<void> startPractice() async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    await ref.read(contextCompactionServiceProvider).init(newId);

    _initSession(practice: true, sessionId: newId);
    _persist();
  }

  Future<void> startDemoScenario(DemoScenario scenario) async {
    final protocolService = ref.read(protocolServiceProvider);
    if (!state.isProtocolLoaded) {
      await protocolService.loadProtocol();
      state = state.copyWith(isProtocolLoaded: true);
    }

    final newId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(contextCompactionServiceProvider).init(newId);

    final demoNode =
        protocolService.getNode(scenario.currentNodeId) ??
        protocolService.startNode;

    state = state.copyWith(
      currentSessionId: newId,
      isEmergencyActive: true,
      isPracticeMode: true,
      currentNode: demoNode,
      streamingBuffer: '',
      isLlmTyping: false,
      situationSummary: scenario.situationSummary,
      locationHistory: [],
      chatHistory: scenario.toChatMessages(),
    );
    _persist();
  }

  Future<void> resumeSession(String id) async {
    final persistence = ref.read(sessionPersistenceServiceProvider);
    final restored = await persistence.loadSession(id);

    if (restored != null) {
      final protocolService = ref.read(protocolServiceProvider);
      await ref.read(contextCompactionServiceProvider).init(id);

      state = state.copyWith(
        currentSessionId: id,
        isEmergencyActive: true,
        isPracticeMode: restored.isPracticeMode,
        currentNode: restored.currentNodeId != null
            ? protocolService.getNode(restored.currentNodeId!)
            : null,
        chatHistory: restored.chatHistory,
        situationSummary: restored.situationSummary,
        locationHistory: restored.locationHistory,
      );
    }
  }

  Future<void> deleteSession(String id) async {
    final persistence = ref.read(sessionPersistenceServiceProvider);
    await persistence.deleteSession(id);
    if (state.currentSessionId == id) {
      state = state.copyWith(
        isEmergencyActive: false,
        clearSessionId: true,
        chatHistory: [],
        situationSummary: '',
        locationHistory: [],
        clearCurrentNode: true,
      );
    }
    await refreshHistory();
  }

  void addLocationFix(GpsCoordinates coords) {
    final updatedHistory = List<GpsCoordinates>.from(state.locationHistory)
      ..add(coords);

    state = state.copyWith(locationHistory: updatedHistory);
    _persist();
  }

  void _initSession({required bool practice, required String sessionId}) {
    if (!state.isProtocolLoaded) return;

    final protocolService = ref.read(protocolServiceProvider);
    final startNode = protocolService.startNode;

    state = state.copyWith(
      currentSessionId: sessionId,
      isEmergencyActive: true,
      isPracticeMode: practice,
      currentNode: startNode,
      streamingBuffer: '',
      situationSummary: '',
      locationHistory: [],
      chatHistory: [
        ChatMessage(
          text: practice
              ? '[PRACTICE MODE] ${startNode.question}'
              : startNode.question,
          author: MessageAuthor.ai,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void handleUserSelection(Branch branch) {
    final List<ChatMessage> updatedHistory =
        List<ChatMessage>.from(state.chatHistory)..add(
          ChatMessage(
            text: branch.label,
            author: MessageAuthor.user,
            timestamp: DateTime.now(),
          ),
        );

    final protocolService = ref.read(protocolServiceProvider);
    final nextNode = protocolService.getNode(branch.target);

    if (nextNode != null && branch.target != 'start') {
      // A protocol button was tapped — add the node question to chat
      // but also trigger Gemma to give context-aware commentary on the step
      updatedHistory.add(
        ChatMessage(
          text: nextNode.question,
          author: MessageAuthor.ai,
          timestamp: DateTime.now(),
        ),
      );

      state = state.copyWith(
        currentNode: nextNode,
        chatHistory: updatedHistory,
      );

      // Optionally: silently update context compaction with the selection
      ref
          .read(contextCompactionServiceProvider)
          .addExchange(
            userMessage: ChatMessage(
              text: branch.label,
              author: MessageAuthor.user,
              timestamp: DateTime.now(),
            ),
            aiResponse: ChatMessage(
              text: nextNode.question,
              author: MessageAuthor.ai,
              timestamp: DateTime.now(),
            ),
          );
    } else if (branch.target == 'end') {
      state = state.copyWith(isEmergencyActive: false);
      if (state.currentSessionId != null) {
        ref
            .read(sessionPersistenceServiceProvider)
            .deleteSession(state.currentSessionId!);
        ref.read(contextCompactionServiceProvider).clearSession();
      }
    } else {
      // "start" self-loop — let Gemma handle the free-form input
      state = state.copyWith(chatHistory: updatedHistory);
    }
    _persist();
  }

  /// The main pipeline: user types → context built → Gemma streams response → context compacted.
  Future<void> handleFreeformInput(String userText, {String? imagePath}) async {
    if (userText.trim().isEmpty && imagePath == null) return;

    // 1. Immediately show user message
    final List<ChatMessage> withUser = List<ChatMessage>.from(state.chatHistory)
      ..add(
        ChatMessage(
          text: userText,
          imagePath: imagePath,
          author: MessageAuthor.user,
          timestamp: DateTime.now(),
        ),
      );
    state = state.copyWith(
      chatHistory: withUser,
      isLlmTyping: true,
      streamingBuffer: '',
    );
    _persist();

    // 2. Build context for Gemma
    final compactionService = ref.read(contextCompactionServiceProvider);
    final protocolService = ref.read(protocolServiceProvider);
    final llm = ref.read(llmServiceProvider.notifier);

    // Extract last AI message to structurally prevent repetition in the prompt
    final lastAiMessage = state.chatHistory
        .lastWhere(
          (m) => m.author == MessageAuthor.ai,
          orElse: () => ChatMessage(
            text: '',
            author: MessageAuthor.ai,
            timestamp: DateTime.now(),
          ),
        )
        .text;

    compactionService.noteUserMessage(
      userText,
      previousAiMessage: lastAiMessage.isNotEmpty ? lastAiMessage : null,
    );

    final situationContext = compactionService.getPromptContext(
      lastAiMessage: lastAiMessage.isNotEmpty ? lastAiMessage : null,
      currentUserMessage: userText,
    );
    final recentHistory = compactionService.getRecentMessages(count: 14);

    // Map incident types to relevant documentation nodes. For mixed field
    // injuries, route by the decision the user needs now rather than the first
    // symptom mentioned, so minor bleeding does not trap the conversation.
    final incident = compactionService.context.incidentType.toLowerCase();
    final summary = state.situationSummary.toLowerCase();
    final userMsgLower = userText.toLowerCase();
    final promptContextLower = situationContext.toLowerCase();
    final combined = '$incident $summary $userMsgLower $promptContextLower';
    bool hasAny(List<String> terms) => terms.any(combined.contains);
    final runnerFieldInjury =
        hasAny([
          'forest',
          'trail',
          'woods',
          'running',
          'runner',
          'jogging',
          'stumbled',
        ]) &&
        hasAny(['knee', 'ankle', 'leg', 'fell', 'fall', 'injury', 'wound']);
    final controlledAndMobile =
        hasAny([
          'bleeding has stopped',
          'bleeding stopped',
          'stopped bleeding',
          'not bleeding anymore',
          'bleeding is not heavy',
        ]) &&
        hasAny(['can stand', 'can walk', 'can put weight', 'can bear weight']);
    String effectiveNodeId = state.currentNode?.id ?? 'start';
    if (runnerFieldInjury && controlledAndMobile) {
      effectiveNodeId = 'evacuation_triage';
    } else if (effectiveNodeId == 'start') {
      // NOTE: burn must be checked BEFORE bleed — cooking burns involve no bleeding
      if (incident.contains('burn') ||
          userMsgLower.contains('burn') ||
          userMsgLower.contains('burned') ||
          summary.contains('burn')) {
        effectiveNodeId = 'burn_protocol';
      } else if (runnerFieldInjury) {
        effectiveNodeId = 'injury_assessment';
      } else if (incident.contains('bleed') ||
          incident.contains('cut') ||
          incident.contains('wound') ||
          userMsgLower.contains('cut') ||
          userMsgLower.contains('bleeding') ||
          summary.contains('bleed') ||
          summary.contains('cut') ||
          summary.contains('wound') ||
          summary.contains('sangr')) {
        effectiveNodeId = 'bleeding_protocol';
      } else if (incident.contains('fall') ||
          incident.contains('knee') ||
          incident.contains('elbow') ||
          summary.contains('fall')) {
        effectiveNodeId = 'injury_assessment';
      } else if (incident.contains('heart') ||
          incident.contains('chest') ||
          summary.contains('chest')) {
        effectiveNodeId = 'chest_pain_protocol';
      } else if (hasAny([
        'stroke',
        'face droop',
        'slurred',
        'one side',
        'one-sided',
        'arm weakness',
        'weak on one',
        'trouble speaking',
      ])) {
        effectiveNodeId = 'stroke_protocol';
      } else if (hasAny([
        'asthma',
        'inhaler',
        'wheezing',
        'shortness of breath',
      ])) {
        effectiveNodeId = 'asthma_breathing_protocol';
      } else if (incident.contains('chok') || summary.contains('chok')) {
        effectiveNodeId = 'choking_protocol';
      } else if (incident.contains('seiz') || summary.contains('seiz')) {
        effectiveNodeId = 'seizure_protocol';
      } else if (incident.contains('frost') ||
          incident.contains('freeze') ||
          summary.contains('cold')) {
        effectiveNodeId = 'frostbite_protocol';
      } else if (incident.contains('lost') || summary.contains('lost')) {
        effectiveNodeId = 'lost_protocol';
      } else if (incident.contains('earthquake') ||
          incident.contains('shaking')) {
        effectiveNodeId = 'earthquake_protocol';
      } else if (incident.contains('flood') || summary.contains('flood')) {
        effectiveNodeId = 'flood_protocol';
      } else if (incident.contains('wildfire') || incident.contains('fire')) {
        effectiveNodeId = 'wildfire_protocol';
      } else if (incident.contains('storm') ||
          incident.contains('tornado') ||
          incident.contains('hurricane')) {
        effectiveNodeId = 'storm_protocol';
      } else if (hasAny([
        'power outage',
        'blackout',
        'no electricity',
        'generator',
        'medical device power',
      ])) {
        effectiveNodeId = 'power_outage_protocol';
      } else if (hasAny([
        'carbon monoxide',
        'co alarm',
        'co detector',
        'generator indoors',
        'headache dizziness',
      ])) {
        effectiveNodeId = 'carbon_monoxide_protocol';
      } else if (hasAny([
        'gas leak',
        'smell gas',
        'hissing gas',
        'propane leak',
      ])) {
        effectiveNodeId = 'gas_leak_protocol';
      } else if (hasAny([
        'chemical spill',
        'chemical release',
        'toxic cloud',
        'hazmat',
        'fumes',
      ])) {
        effectiveNodeId = 'chemical_spill_protocol';
      } else if (hasAny([
        'outbreak',
        'infectious',
        'infection spreading',
        'pandemic',
        'quarantine',
        'isolate',
      ])) {
        effectiveNodeId = 'infectious_disease_protocol';
      } else if (incident.contains('water') ||
          incident.contains('drink') ||
          summary.contains('water')) {
        effectiveNodeId = 'water_skills';
      } else if (incident.contains('food') ||
          incident.contains('hungry') ||
          summary.contains('food')) {
        effectiveNodeId = 'food_skills';
      } else if (incident.contains('shelter') ||
          incident.contains('sleep') ||
          summary.contains('shelter')) {
        effectiveNodeId = 'shelter_skills';
      } else if (incident.contains('navigat') ||
          summary.contains('direction') ||
          summary.contains('where')) {
        effectiveNodeId = 'nav_skills';
      } else if (hasAny([
        'overdose',
        'naloxone',
        'narcan',
        'opioid',
        'fentanyl',
        'heroin',
        'too many pills',
      ])) {
        effectiveNodeId = 'opioid_overdose_protocol';
      } else if (incident.contains('poison') || summary.contains('poison')) {
        effectiveNodeId = 'poisoning_protocol';
      } else if (hasAny([
        'pregnant',
        'pregnancy',
        'labor',
        'contractions',
        'water broke',
        'giving birth',
      ])) {
        effectiveNodeId = 'pregnancy_labor_protocol';
      } else if (hasAny([
        'suicide',
        'self harm',
        'kill myself',
        'kill himself',
        'kill herself',
        'mental health crisis',
        'panic attack',
      ])) {
        effectiveNodeId = 'mental_health_crisis_protocol';
      } else if (hasAny([
        'many injured',
        'multiple injured',
        'mass casualty',
        'explosion',
        'crowd crush',
      ])) {
        effectiveNodeId = 'mass_casualty_triage';
      }
    }

    final effectiveNode = protocolService.getNode(effectiveNodeId);
    if (effectiveNode != null && effectiveNode.id != state.currentNode?.id) {
      state = state.copyWith(currentNode: effectiveNode);
    }

    final knowledgeBase = protocolService.getDocumentationForNode(
      effectiveNodeId,
    );

    // 3. Stream Gemma's response token by token
    final responseBuffer = StringBuffer();
    var responseWasCapped = false;

    await for (final token in llm.generateResponseStream(
      userMessage: (userText.isEmpty && imagePath != null)
          ? "Analyze this image."
          : userText,
      situationContext: situationContext,
      knowledgeBase: knowledgeBase.isNotEmpty
          ? knowledgeBase
          : 'General wilderness emergency. Apply Red Cross first aid principles.',
      recentHistory: recentHistory,
      imagePath: imagePath,
      lastAiMessage: lastAiMessage.isNotEmpty ? lastAiMessage : null,
    )) {
      responseBuffer.write(token);
      if (responseBuffer.length > 620) {
        responseWasCapped = true;
        state = state.copyWith(streamingBuffer: '');
        break;
      }
      // Update streaming buffer in state so UI can show live typing
      state = state.copyWith(streamingBuffer: responseBuffer.toString());
    }

    var fullResponse = responseBuffer.toString().trim();
    if (ConversationGuard.looksLikeExtractionJson(fullResponse) ||
        fullResponse.contains('[Error:') ||
        responseWasCapped ||
        ConversationGuard.isTooLongOrArticleStyle(fullResponse) ||
        ConversationGuard.skipsInitialFieldTriage(
          ctx: compactionService.context,
          response: fullResponse,
        ) ||
        ConversationGuard.asksAnsweredFact(
          ctx: compactionService.context,
          response: fullResponse,
        ) ||
        ConversationGuard.repeatsLastQuestion(
          previousAiMessage: lastAiMessage,
          response: fullResponse,
        )) {
      fullResponse = ConversationGuard.fallbackResponseForContext(
        compactionService.context,
      );
    }

    // 4. Finalize: move streaming buffer to chat history
    final withResponse = List<ChatMessage>.from(state.chatHistory)
      ..add(
        ChatMessage(
          text: fullResponse,
          author: MessageAuthor.ai,
          timestamp: DateTime.now(),
        ),
      );
    state = state.copyWith(
      chatHistory: withResponse,
      isLlmTyping: false,
      streamingBuffer: '',
    );

    // 4. Update compaction service and persist
    final aiMessage = ChatMessage(
      text: fullResponse,
      author: MessageAuthor.ai,
      timestamp: DateTime.now(),
    );

    await compactionService.addExchange(
      userMessage: withUser.last,
      aiResponse: aiMessage,
    );

    // 6. Update situation summary display
    final ctx = compactionService.context;
    if (ctx.summary.isNotEmpty) {
      state = state.copyWith(situationSummary: ctx.summary);
    } else if (ctx.confirmedLacks.isNotEmpty ||
        ctx.confirmedResources.isNotEmpty) {
      // Build a mini-summary from extracted facts
      final parts = <String>[];
      if (ctx.isAlone == true) parts.add('alone');
      if (ctx.injuryType != null) parts.add(ctx.injuryType!);
      if (ctx.confirmedLacks.isNotEmpty) {
        parts.add('no ${ctx.confirmedLacks.join('/')}');
      }
      state = state.copyWith(situationSummary: parts.join(' | '));
    }

    _persist();
  }

  String generateMarkdownExport() {
    final compactionService = ref.read(contextCompactionServiceProvider);
    final ctx = compactionService.context;
    final attachedImages = state.chatHistory
        .where((message) => message.imagePath != null)
        .map((message) => message.imagePath!)
        .toList();
    final userMessages = state.chatHistory
        .where((message) => message.author == MessageAuthor.user)
        .map((message) => message.text)
        .where((text) => text.trim().isNotEmpty)
        .toList();
    final summary = state.situationSummary.isNotEmpty
        ? state.situationSummary
        : userMessages.take(2).join(' ');

    final buffer = StringBuffer();
    buffer.writeln('# AIDEM Rescue Handoff');
    buffer.writeln('Generated on: ${DateTime.now().toLocal()}');
    buffer.writeln('Mode: ${state.isPracticeMode ? "PRACTICE" : "EMERGENCY"}');
    buffer.writeln(
      'Current protocol: ${state.currentNode?.id ?? "conversation"}',
    );
    buffer.writeln();

    buffer.writeln('## Safety Notes');
    buffer.writeln('- AIDEM is protocol-based emergency decision support.');
    buffer.writeln(
      '- Call emergency services first whenever they are reachable.',
    );
    buffer.writeln(
      '- Image observations are limited and should not be treated as diagnosis.',
    );
    buffer.writeln('- Session data is intended to stay local to this device.');
    buffer.writeln();

    buffer.writeln('## Situation Summary');
    buffer.writeln(summary.isNotEmpty ? summary : 'No summary available.');
    buffer.writeln();

    buffer.writeln('## Dispatcher Script');
    buffer.writeln(
      summary.isNotEmpty
          ? 'I need emergency assistance. Situation: $summary. I can provide GPS coordinates, hazards, current condition, and actions already taken.'
          : 'I need emergency assistance. I can provide GPS coordinates, hazards, current condition, and actions already taken.',
    );
    buffer.writeln();

    buffer.writeln('## Emergency Dispatch Intake (ETHANE)');
    buffer.writeln(
      '- **Exact Location:** ${_valueOrUnknown(ctx.locationDetails)}',
    );
    buffer.writeln(
      '- **Type of Incident:** ${_valueOrUnknown(ctx.incidentType)}',
    );
    buffer.writeln('- **Hazards:** ${_valueOrUnknown(ctx.hazards)}');
    buffer.writeln('- **Access & Egress:** ${_valueOrUnknown(ctx.accessInfo)}');
    buffer.writeln(
      '- **Number of Patients:** ${_valueOrUnknown(ctx.patientCount)}',
    );
    buffer.writeln('- **Urgency Level:** ${_valueOrUnknown(ctx.urgencyLevel)}');
    buffer.writeln();

    buffer.writeln('## Handoff Checklist');
    buffer.writeln('- **Known hazards:** ${_valueOrUnknown(ctx.hazards)}');
    buffer.writeln(
      '- **Current condition:** ${ctx.injuryType ?? ctx.incidentType}',
    );
    buffer.writeln(
      '- **Actions already taken:** ${ctx.completedSteps.isEmpty ? "None logged" : ctx.completedSteps.join(", ")}',
    );
    buffer.writeln(
      '- **Available resources:** ${ctx.confirmedResources.isEmpty ? "None confirmed" : ctx.confirmedResources.join(", ")}',
    );
    buffer.writeln(
      '- **Missing resources:** ${ctx.confirmedLacks.isEmpty ? "None confirmed" : ctx.confirmedLacks.join(", ")}',
    );
    buffer.writeln(
      '- **Attached images:** ${attachedImages.isEmpty ? "None" : attachedImages.length}',
    );
    buffer.writeln(
      '- **GPS fixes logged:** ${state.locationHistory.isEmpty ? "None" : state.locationHistory.length}',
    );
    buffer.writeln();

    if (state.locationHistory.isNotEmpty) {
      final latest = state.locationHistory.last;
      buffer.writeln('## Location Timeline');
      buffer.writeln(
        '- **Latest Decimal:** ${latest.latitude.toStringAsFixed(6)}, ${latest.longitude.toStringAsFixed(6)}',
      );
      buffer.writeln('- **Latest DMS:** ${latest.toDms()}');
      if (latest.altitude != null) {
        buffer.writeln(
          '- **Latest Altitude:** ${latest.altitude!.toStringAsFixed(0)} m',
        );
      }
      buffer.writeln();
      for (final fix in state.locationHistory.reversed.take(10)) {
        final timestamp = fix.timestamp.toLocal().toString().split('.')[0];
        buffer.writeln(
          '- [$timestamp] ${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)} | ${fix.toDms()}',
        );
      }
      buffer.writeln();
    }

    if (attachedImages.isNotEmpty) {
      buffer.writeln('## Attached Image References');
      for (final path in attachedImages) {
        buffer.writeln('- `$path`');
      }
      buffer.writeln();
    }

    buffer.writeln('## Internal Context & Decisions');
    buffer.writeln('- **Injury Type:** ${ctx.injuryType ?? "Unknown"}');
    buffer.writeln('- **Environment:** ${ctx.environment ?? "Unknown"}');
    buffer.writeln('- **Is Alone:** ${ctx.isAlone ?? "Unknown"}');
    buffer.writeln(
      '- **Resources:** ${ctx.confirmedResources.isEmpty ? "None confirmed" : ctx.confirmedResources.join(", ")}',
    );
    buffer.writeln(
      '- **Lacks:** ${ctx.confirmedLacks.isEmpty ? "None confirmed" : ctx.confirmedLacks.join(", ")}',
    );
    buffer.writeln(
      '- **Answered Facts:** ${ctx.answeredFacts.isEmpty ? "None" : ctx.answeredFacts.join(", ")}',
    );
    buffer.writeln(
      '- **Completed Steps:** ${ctx.completedSteps.isEmpty ? "None" : ctx.completedSteps.join(", ")}',
    );
    buffer.writeln(
      '- **Current Protocol Node:** ${state.currentNode?.id ?? "None"}',
    );
    buffer.writeln();

    buffer.writeln('## Timeline');
    buffer.writeln();
    for (final msg in state.chatHistory) {
      final role = msg.author == MessageAuthor.ai ? 'Gemma' : 'User';
      final timestamp = msg.timestamp.toLocal().toString().split('.')[0];
      buffer.writeln('### [$timestamp] $role');
      buffer.writeln(msg.text);
      if (msg.imagePath != null) {
        buffer.writeln();
        buffer.writeln('Image: `${msg.imagePath}`');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _valueOrUnknown(Object? value) {
    final trimmed = value?.toString().trim() ?? '';
    return trimmed.isEmpty ? 'Unknown' : trimmed;
  }
}
