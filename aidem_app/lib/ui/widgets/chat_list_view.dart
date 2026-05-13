import 'package:flutter/material.dart';
import '../../models/protocol.dart';
import 'chat_bubble.dart';

class ChatListView extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const ChatListView({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: messages[index]);
      },
    );
  }
}
