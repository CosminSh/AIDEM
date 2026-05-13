import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tactical_container.dart';

class DiagramCard extends StatelessWidget {
  final String imagePath;
  final String caption;

  const DiagramCard({
    super.key,
    required this.imagePath,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return TacticalContainer(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.zero,
      showGlow: false,
      borderRadius: AppColors.radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppColors.radius),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              caption,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
