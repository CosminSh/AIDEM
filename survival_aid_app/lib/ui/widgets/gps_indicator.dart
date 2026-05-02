import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum GpsStatus { acquiring, ready, error }

class GpsIndicator extends StatelessWidget {
  final GpsStatus status;

  const GpsIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case GpsStatus.acquiring:
        color = AppColors.warning;
        label = "ACQUIRING GPS...";
        break;
      case GpsStatus.ready:
        color = AppColors.success;
        label = "GPS READY";
        break;
      case GpsStatus.error:
        color = AppColors.accentRed;
        label = "GPS ERROR";
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
