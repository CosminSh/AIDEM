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
    final textStyle = isAi
        ? GoogleFonts.inter(
            color: AppColors.brandAi,
            fontSize: wide ? 17 : 16,
            fontWeight: FontWeight.w700,
            height: 1.42,
            letterSpacing: 0,
          )
        : GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.48,
            letterSpacing: 0,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Align(
        alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          padding: EdgeInsets.fromLTRB(16, isAi ? 15 : 14, 16, 15),
          decoration: BoxDecoration(
            color: isAi
                ? AppColors.surfaceElevated.withValues(alpha: 0.58)
                : AppColors.brandAi.withValues(alpha: 0.14),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isAi ? 8 : 18),
              bottomRight: Radius.circular(isAi ? 18 : 8),
            ),
            border: Border.all(
              color: isAi
                  ? AppColors.brandAi.withValues(alpha: 0.18)
                  : AppColors.brandAi.withValues(alpha: 0.34),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                spreadRadius: -15,
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
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _BubbleBadge(
                        icon: Icons.psychology_outlined,
                        label: 'AIDEM',
                        color: AppColors.brandAi,
                      ),
                      _BubbleBadge(
                        icon: Icons.fact_check_outlined,
                        label: 'Protocol',
                        color: AppColors.accentBlue,
                      ),
                    ],
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
                          color: Colors.black.withValues(alpha: 0.1),
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
              SelectableText(message.text, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BubbleBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
