import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PracticeModeOverlay extends StatelessWidget {
  const PracticeModeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.035,
              child: Transform.rotate(
                angle: -0.5,
                child: const Text(
                  "PRACTICE MODE",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: AppColors.accentBlue.withOpacity(0.72),
              child: const Text(
                "Practice mode - no real emergency active",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
