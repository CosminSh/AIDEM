import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PracticeModeOverlay extends StatelessWidget {
  const PracticeModeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer( // Allow interactions to pass through to the chat
      child: Stack(
        children: [
          // Watermark in the background
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Transform.rotate(
                angle: -0.5,
                child: const Text(
                  "PRACTICE MODE",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          
          // Top Banner
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: AppColors.accentBlue.withOpacity(0.8),
              child: const Text(
                "TRAINING MODE - NO REAL EMERGENCY ACTIVE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
