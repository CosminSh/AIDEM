import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAi = message.author == MessageAuthor.ai;
    final screenWidth = MediaQuery.of(context).size.width;
    final wide = screenWidth > 760;
    final maxBubbleWidth = wide ? 720.0 : screenWidth * 0.86;
    final isGuidance = isAi && message.text.length > 120;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isGuidance ? 12 : 7,
        horizontal: 16,
      ),
      child: Align(
        alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          padding: EdgeInsets.all(isGuidance ? 18 : 16),
          decoration: BoxDecoration(
            color: isGuidance
                ? Colors.transparent
                : isAi
                ? AppColors.surfaceElevated.withValues(alpha: 0.64)
                : AppColors.brandAi.withValues(alpha: 0.14),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isAi ? 8 : 18),
              bottomRight: Radius.circular(isAi ? 18 : 8),
            ),
            border: isGuidance
                ? null
                : Border.all(
                    color: isAi
                        ? AppColors.border
                        : AppColors.brandAi.withValues(alpha: 0.34),
                    width: 1,
                  ),
            boxShadow: isGuidance
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      spreadRadius: -16,
                      offset: const Offset(0, 14),
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
                    style: GoogleFonts.inter(
                      color: AppColors.brandAi,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
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
                style: GoogleFonts.inter(
                  color: isGuidance ? AppColors.brandAi : AppColors.textPrimary,
                  fontSize: isGuidance ? (wide ? 24 : 18) : 15,
                  fontWeight: isGuidance ? FontWeight.w700 : FontWeight.w500,
                  height: isGuidance ? 1.35 : 1.55,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
