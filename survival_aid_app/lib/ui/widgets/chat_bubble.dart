import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAi = message.author == MessageAuthor.ai;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth > 760 ? 620.0 : screenWidth * 0.86;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 16.0),
      child: Align(
        alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isAi
                ? AppColors.surfaceElevated
                : AppColors.accentBlue.withOpacity(0.13),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppColors.radius),
              topRight: const Radius.circular(AppColors.radius),
              bottomLeft: Radius.circular(isAi ? 6.0 : AppColors.radius),
              bottomRight: Radius.circular(isAi ? AppColors.radius : 6.0),
            ),
            border: Border.all(
              color: isAi
                  ? AppColors.border
                  : AppColors.accentBlue.withOpacity(0.34),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: -14,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'AIDEM',
                    style: TextStyle(
                      color: AppColors.brandAi,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              if (message.imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(message.imagePath!),
                      fit: BoxFit.cover,
                      width: maxBubbleWidth,
                      height: 180,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, color: Colors.white70),
                            SizedBox(width: 8),
                            Text(
                              'Image unavailable',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SelectableText(
                message.text,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
