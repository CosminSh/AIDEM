import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ui_sound_service.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          UiSoundService.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppColors.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: hasImage
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppColors.radius),
            border: Border.all(
              color: hasImage ? AppColors.success : AppColors.border,
              width: 1,
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
                hasImage ? "Image captured" : "Capture wound image",
                style: TextStyle(
                  color: hasImage ? AppColors.success : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
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
