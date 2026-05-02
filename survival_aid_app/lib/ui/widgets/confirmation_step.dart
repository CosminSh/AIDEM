import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConfirmationStep extends StatelessWidget {
  final String label;
  final VoidCallback onConfirmed;

  const ConfirmationStep({
    super.key,
    this.label = "DONE - CONTINUE",
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: onConfirmed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius),
          ),
          elevation: 4,
          shadowColor: AppColors.success.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 24),
            const SizedBox(width: 12),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
