import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAi = message.author == MessageAuthor.ai;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isAi ? AppColors.surface : AppColors.accentBlue,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppColors.radius),
              topRight: const Radius.circular(AppColors.radius),
              bottomLeft: Radius.circular(isAi ? 4.0 : AppColors.radius),
              bottomRight: Radius.circular(isAi ? AppColors.radius : 4.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SelectableText(
            message.text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
