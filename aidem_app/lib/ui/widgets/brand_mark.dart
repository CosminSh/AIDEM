import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AidemBrandMark extends StatelessWidget {
  final double size;
  final bool framed;
  final bool glow;
  final EdgeInsetsGeometry padding;

  const AidemBrandMark({
    super.key,
    required this.size,
    this.framed = true,
    this.glow = true,
    this.padding = const EdgeInsets.all(7),
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/aidem_mark.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!framed) {
      return SizedBox(width: size, height: size, child: image);
    }

    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: AppColors.brandAi.withValues(alpha: 0.24)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.brandAi.withValues(alpha: 0.14),
                  blurRadius: size * 0.42,
                  spreadRadius: -size * 0.22,
                ),
              ]
            : null,
      ),
      child: image,
    );
  }
}
