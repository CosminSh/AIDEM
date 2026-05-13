import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tactical_container.dart';

class LlmLoadingBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String statusText;

  const LlmLoadingBar({
    super.key,
    required this.progress,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return TacticalContainer(
      padding: const EdgeInsets.all(24),
      showGlow: false,
      borderRadius: AppColors.radius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentBlue,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Gemma 2B is loading for offline AI assistance. This only happens once per session.",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
