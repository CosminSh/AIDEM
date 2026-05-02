import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/protocol.dart';
import 'global_providers.dart';

class SessionState {
  final ProtocolNode? currentNode;
  final List<ChatMessage> chatHistory;
  final bool isEmergencyActive;
  final bool isPracticeMode;
  final bool isProtocolLoaded;

  SessionState({
    this.currentNode,
    required this.chatHistory,
    required this.isEmergencyActive,
    required this.isPracticeMode,
    this.isProtocolLoaded = false,
  });

  SessionState copyWith({
    ProtocolNode? currentNode,
    List<ChatMessage>? chatHistory,
    bool? isEmergencyActive,
    bool? isPracticeMode,
    bool? isProtocolLoaded,
  }) {
    return SessionState(
      currentNode: currentNode ?? this.currentNode,
      chatHistory: chatHistory ?? this.chatHistory,
      isEmergencyActive: isEmergencyActive ?? this.isEmergencyActive,
      isPracticeMode: isPracticeMode ?? this.isPracticeMode,
      isProtocolLoaded: isProtocolLoaded ?? this.isProtocolLoaded,
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
    state = state.copyWith(isProtocolLoaded: true);
  }

  void startEmergency() {
    _initSession(practice: false);
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
      chatHistory: [
        ChatMessage(
          text: practice ? "[PRACTICE MODE] " + startNode.question : startNode.question,
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
    
    if (nextNode != null) {
      updatedHistory.add(ChatMessage(
        text: nextNode.question,
        author: MessageAuthor.ai,
        timestamp: DateTime.now(),
      ));
      
      state = state.copyWith(
        currentNode: nextNode,
        chatHistory: updatedHistory,
      );
    } else if (branch.target == 'end') {
      state = state.copyWith(isEmergencyActive: false);
    }
  }

  Future<void> handleFreeformInput(String userText) async {
    // 1. Append user message immediately so UI feels responsive
    final List<ChatMessage> withUser = List<ChatMessage>.from(state.chatHistory)
      ..add(ChatMessage(
        text: userText,
        author: MessageAuthor.user,
        timestamp: DateTime.now(),
      ));
    state = state.copyWith(chatHistory: withUser);

    // 2. Build conversation history for context window
    final history = state.chatHistory
        .map((m) => "${m.author == MessageAuthor.ai ? 'Assistant' : 'User'}: ${m.text}")
        .toList();

    // 3. Get current protocol context
    final protocolContext = state.currentNode?.question ?? "General wilderness emergency.";

    // 4. Call LLM (Gemma via mock/production)
    final llm = ref.read(llmServiceProvider);
    final response = await llm.generateResponse(
      conversationHistory: history,
      currentProtocolContext: protocolContext,
      userMessage: userText,
    );

    // 5. Append AI response
    final withResponse = List<ChatMessage>.from(state.chatHistory)
      ..add(ChatMessage(
        text: response,
        author: MessageAuthor.ai,
        timestamp: DateTime.now(),
      ));
    state = state.copyWith(chatHistory: withResponse);
  }
}
