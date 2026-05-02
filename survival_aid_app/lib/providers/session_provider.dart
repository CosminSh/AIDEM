import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/protocol.dart';
import 'global_providers.dart';

class SessionState {
  final ProtocolNode? currentNode;
  final List<ChatMessage> chatHistory;
  final bool isEmergencyActive;
  final bool isPracticeMode;
  final bool isProtocolLoaded;
  final bool isLlmTyping;
  final String streamingBuffer; // tokens arriving from Gemma in real-time
  final String situationSummary; // compact situation for UI display

  SessionState({
    this.currentNode,
    required this.chatHistory,
    required this.isEmergencyActive,
    required this.isPracticeMode,
    this.isProtocolLoaded = false,
    this.isLlmTyping = false,
    this.streamingBuffer = '',
    this.situationSummary = '',
  });

  SessionState copyWith({
    ProtocolNode? currentNode,
    List<ChatMessage>? chatHistory,
    bool? isEmergencyActive,
    bool? isPracticeMode,
    bool? isProtocolLoaded,
    bool? isLlmTyping,
    String? streamingBuffer,
    String? situationSummary,
    bool clearCurrentNode = false,
  }) {
    return SessionState(
      currentNode: clearCurrentNode ? null : (currentNode ?? this.currentNode),
      chatHistory: chatHistory ?? this.chatHistory,
      isEmergencyActive: isEmergencyActive ?? this.isEmergencyActive,
      isPracticeMode: isPracticeMode ?? this.isPracticeMode,
      isProtocolLoaded: isProtocolLoaded ?? this.isProtocolLoaded,
      isLlmTyping: isLlmTyping ?? this.isLlmTyping,
      streamingBuffer: streamingBuffer ?? this.streamingBuffer,
      situationSummary: situationSummary ?? this.situationSummary,
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
    );
  }

  Future<void> initialize() async {
    final protocolService = ref.read(protocolServiceProvider);
    await protocolService.loadProtocol();

    // Also initialize the LLM
    final llm = ref.read(llmServiceProvider);
    await llm.init();

    state = state.copyWith(isProtocolLoaded: true);
  }

  Future<void> startEmergency() async {
    // Re-verify/Initialize LLM on start to ensure it's ready
    await ref.read(llmServiceProvider).init();
    
    _initSession(practice: false);
    // Clear previous session context when starting a new emergency
    ref.read(contextCompactionServiceProvider).clearSession();
  }

  void startPractice() {
    _initSession(practice: true);
  }

  void _initSession({required bool practice}) {
    if (!state.isProtocolLoaded) return;

    final protocolService = ref.read(protocolServiceProvider);
    final startNode = protocolService.startNode;

    state = state.copyWith(
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
    } else {
      // "start" self-loop — let Gemma handle the free-form input
      state = state.copyWith(chatHistory: updatedHistory);
    }
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

    // 2. Build context for Gemma
    final compactionService = ref.read(contextCompactionServiceProvider);
    final protocolService = ref.read(protocolServiceProvider);
    final llm = ref.read(llmServiceProvider);

    final situationContext = compactionService.getPromptContext();
    final recentHistory = compactionService.getRecentMessages(count: 8);
    final knowledgeBase = state.currentNode != null
        ? protocolService.getDocumentationForNode(state.currentNode!.id)
        : protocolService.getDocumentationForNode('start');

    // 3. Stream Gemma's response token by token
    final responseBuffer = StringBuffer();

    await for (final token in llm.generateResponseStream(
      userMessage: userText,
      situationContext: situationContext.isEmpty
          ? 'No prior context — this is the first message.'
          : situationContext,
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
      if (ctx.isAlone) parts.add('alone');
      if (ctx.injuryType != null) parts.add(ctx.injuryType!);
      if (ctx.confirmedLacks.isNotEmpty) parts.add('no ${ctx.confirmedLacks.join('/')}');
      state = state.copyWith(situationSummary: parts.join(' · '));
    }

    // 7. Trigger async compaction after every 4 exchanges
    final msgCount = state.chatHistory.where((m) => m.author == MessageAuthor.user).length;
    if (msgCount % 4 == 0) {
      compactionService.compact((prompt) => llm.generateOnce(prompt));
    }
  }
}
