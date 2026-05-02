import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ImageCaptureButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasImage;

  const ImageCaptureButton({
    super.key,
    required this.onTap,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: hasImage ? AppColors.success.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radius),
          border: Border.all(
            color: hasImage ? AppColors.success : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasImage ? Icons.check_circle : Icons.camera_alt_rounded,
              color: hasImage ? AppColors.success : AppColors.accentBlue,
            ),
            const SizedBox(width: 12),
            Text(
              hasImage ? "IMAGE CAPTURED" : "CAPTURE WOUND IMAGE",
              style: TextStyle(
                color: hasImage ? AppColors.success : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
