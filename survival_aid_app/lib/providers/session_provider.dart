import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/protocol.dart';
import 'global_providers.dart';
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
      currentSessionId: clearSessionId ? null : (currentSessionId ?? this.currentSessionId),
      situationSummary: situationSummary ?? this.situationSummary,
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
      final llm = ref.read(llmServiceProvider);
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

  void _persist() {
    if (state.currentSessionId == null) return;
    
    final persistence = ref.read(sessionPersistenceServiceProvider);
    persistence.saveSession(PersistedSession(
      id: state.currentSessionId!,
      chatHistory: state.chatHistory,
      currentNodeId: state.currentNode?.id,
      isEmergencyActive: state.isEmergencyActive,
      isPracticeMode: state.isPracticeMode,
      situationSummary: state.situationSummary,
      lastUpdated: DateTime.now(),
    ));
    refreshHistory();
  }

  Future<void> startEmergency() async {
    await ref.read(llmServiceProvider).init();
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
        clearCurrentNode: true,
      );
    }
    await refreshHistory();
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
    final List<ChatMessage> updatedHistory = List<ChatMessage>.from(state.chatHistory)
      ..add(ChatMessage(
        text: branch.label,
        author: MessageAuthor.user,
        timestamp: DateTime.now(),
      ));

    final protocolService = ref.read(protocolServiceProvider);
    final nextNode = protocolService.getNode(branch.target);

    if (nextNode != null && branch.target != 'start') {
      // A protocol button was tapped — add the node question to chat
      // but also trigger Gemma to give context-aware commentary on the step
      updatedHistory.add(ChatMessage(
        text: nextNode.question,
        author: MessageAuthor.ai,
        timestamp: DateTime.now(),
      ));

      state = state.copyWith(
        currentNode: nextNode,
        chatHistory: updatedHistory,
      );

      // Optionally: silently update context compaction with the selection
      ref.read(contextCompactionServiceProvider).addExchange(
        userMessage: branch.label,
        aiResponse: nextNode.question,
      );
    } else if (branch.target == 'end') {
      state = state.copyWith(isEmergencyActive: false);
      if (state.currentSessionId != null) {
        ref.read(sessionPersistenceServiceProvider).deleteSession(state.currentSessionId!);
        ref.read(contextCompactionServiceProvider).clearSession();
      }
    } else {
      // "start" self-loop — let Gemma handle the free-form input
      state = state.copyWith(chatHistory: updatedHistory);
    }
    _persist();
  }

  /// The main pipeline: user types → context built → Gemma streams response → context compacted.
  Future<void> handleFreeformInput(String userText) async {
    if (userText.trim().isEmpty) return;

    // 1. Immediately show user message
    final List<ChatMessage> withUser = List<ChatMessage>.from(state.chatHistory)
      ..add(ChatMessage(
        text: userText,
        author: MessageAuthor.user,
        timestamp: DateTime.now(),
      ));
    state = state.copyWith(
      chatHistory: withUser,
      isLlmTyping: true,
      streamingBuffer: '',
    );
    _persist();

    // 2. Build context for Gemma
    final compactionService = ref.read(contextCompactionServiceProvider);
    final protocolService = ref.read(protocolServiceProvider);
    final llm = ref.read(llmServiceProvider);

    final situationContext = compactionService.getPromptContext();
    final recentHistory = compactionService.getRecentMessages(count: 10);
    
    // Map incident types to relevant documentation nodes if current node is 'start'
    String effectiveNodeId = state.currentNode?.id ?? 'start';
    if (effectiveNodeId == 'start') {
      final incident = compactionService.context.incidentType.toLowerCase();
      if (incident.contains('bleed') || incident.contains('cut')) effectiveNodeId = 'bleeding_protocol';
      else if (incident.contains('fall') || incident.contains('knee') || incident.contains('elbow')) effectiveNodeId = 'injury_assessment';
      else if (incident.contains('heart') || incident.contains('chest')) effectiveNodeId = 'chest_pain_protocol';
      else if (incident.contains('chok')) effectiveNodeId = 'choking_protocol';
      else if (incident.contains('seiz')) effectiveNodeId = 'seizure_protocol';
      else if (incident.contains('frost') || incident.contains('freeze')) effectiveNodeId = 'frostbite_protocol';
      else if (incident.contains('lost')) effectiveNodeId = 'lost_protocol';
    }

    final knowledgeBase = protocolService.getDocumentationForNode(effectiveNodeId);

    // 3. Stream Gemma's response token by token
    final responseBuffer = StringBuffer();

    await for (final token in llm.generateResponseStream(
      userMessage: userText,
      situationContext: situationContext,
      knowledgeBase: knowledgeBase.isNotEmpty
          ? knowledgeBase
          : 'General wilderness emergency. Apply Red Cross first aid principles.',
      recentHistory: recentHistory,
    )) {
      responseBuffer.write(token);
      // Update streaming buffer in state so UI can show live typing
      state = state.copyWith(streamingBuffer: responseBuffer.toString());
    }

    final fullResponse = responseBuffer.toString().trim();

    // 4. Finalize: move streaming buffer to chat history
    final withResponse = List<ChatMessage>.from(state.chatHistory)
      ..add(ChatMessage(
        text: fullResponse,
        author: MessageAuthor.ai,
        timestamp: DateTime.now(),
      ));
    state = state.copyWith(
      chatHistory: withResponse,
      isLlmTyping: false,
      streamingBuffer: '',
    );

    // 5. Update compaction service (background)
    await compactionService.addExchange(
      userMessage: userText,
      aiResponse: fullResponse,
    );

    // 6. Update situation summary display
    final ctx = compactionService.context;
    if (ctx.summary.isNotEmpty) {
      state = state.copyWith(situationSummary: ctx.summary);
    } else if (ctx.confirmedLacks.isNotEmpty || ctx.confirmedResources.isNotEmpty) {
      // Build a mini-summary from extracted facts
      final parts = <String>[];
      if (ctx.isAlone == true) parts.add('alone');
      if (ctx.injuryType != null) parts.add(ctx.injuryType!);
      if (ctx.confirmedLacks.isNotEmpty) parts.add('no ${ctx.confirmedLacks.join('/')}');
      state = state.copyWith(situationSummary: parts.join(' · '));
    }

    // 7. Trigger async compaction after every 2 exchanges
    final msgCount = state.chatHistory.where((m) => m.author == MessageAuthor.user).length;
    if (msgCount > 0 && msgCount % 2 == 0) {
      compactionService.compact((prompt) => llm.generateOnce(prompt));
    }
    
    _persist();
  }

  String generateMarkdownExport() {
    final compactionService = ref.read(contextCompactionServiceProvider);
    final ctx = compactionService.context;
    
    final buffer = StringBuffer();
    buffer.writeln('# Survival AId Session Export');
    buffer.writeln('Generated on: ${DateTime.now().toLocal()}');
    buffer.writeln('Mode: ${state.isPracticeMode ? "PRACTICE" : "EMERGENCY"}');
    buffer.writeln();
    
    buffer.writeln('## Situation Summary');
    buffer.writeln(state.situationSummary.isNotEmpty ? state.situationSummary : 'No summary available.');
    buffer.writeln();
    
    buffer.writeln('## Emergency Dispatch Intake (ETHANE)');
    buffer.writeln('- **Exact Location:** ${ctx.locationDetails}');
    buffer.writeln('- **Type of Incident:** ${ctx.incidentType}');
    buffer.writeln('- **Hazards:** ${ctx.hazards}');
    buffer.writeln('- **Access & Egress:** ${ctx.accessInfo}');
    buffer.writeln('- **Number of Patients:** ${ctx.patientCount}');
    buffer.writeln('- **Urgency Level:** ${ctx.urgencyLevel}');
    buffer.writeln();
    
    buffer.writeln('## Internal Context & Decisions');
    buffer.writeln('- **Injury Type:** ${ctx.injuryType ?? "Unknown"}');
    buffer.writeln('- **Environment:** ${ctx.environment ?? "Unknown"}');
    buffer.writeln('- **Is Alone:** ${ctx.isAlone ?? "Unknown"}');
    buffer.writeln('- **Resources:** ${ctx.confirmedResources.isEmpty ? "None confirmed" : ctx.confirmedResources.join(", ")}');
    buffer.writeln('- **Lacks:** ${ctx.confirmedLacks.isEmpty ? "None confirmed" : ctx.confirmedLacks.join(", ")}');
    buffer.writeln('- **Current Protocol Node:** ${state.currentNode?.id ?? "None"}');
    buffer.writeln();
    
    buffer.writeln('## Chat History');
    buffer.writeln();
    for (final msg in state.chatHistory) {
      final role = msg.author == MessageAuthor.ai ? 'Gemma' : 'User';
      final timestamp = msg.timestamp.toLocal().toString().split('.')[0];
      buffer.writeln('### [$timestamp] $role');
      buffer.writeln(msg.text);
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}
