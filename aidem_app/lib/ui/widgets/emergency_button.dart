import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class EmergencyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const EmergencyButton({super.key, required this.onPressed, this.size = 208});

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.025,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coreSize = widget.size * 0.72;

    return Semantics(
      button: true,
      label: 'Start emergency session',
      child: ScaleTransition(
        scale: _animation,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brandAi.withValues(alpha: 0.34),
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.9,
                height: widget.size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brandAi.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandAi.withValues(alpha: 0.18),
                      blurRadius: 46,
                      spreadRadius: -18,
                    ),
                  ],
                ),
              ),
              Container(
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandAi.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.brandAi.withValues(alpha: 0.2),
                  ),
                ),
              ),
              SizedBox(
                width: coreSize,
                height: coreSize,
                child: Material(
                  color: AppColors.surfaceMuted.withValues(alpha: 0.78),
                  shadowColor: AppColors.brandAi.withValues(alpha: 0.26),
                  elevation: 0,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onPressed,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monitor_heart_outlined,
                            color: AppColors.brandAi,
                            size: widget.size * 0.16,
                          ),
                          SizedBox(height: widget.size * 0.06),
                          Text(
                            "I NEED\nHELP",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textPrimary,
                              fontSize: widget.size * 0.11,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: widget.size * 0.05),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandAi.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.brandAi.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            ),
                            child: Text(
                              'START SESSION',
                              style: GoogleFonts.inter(
                                color: AppColors.brandAi,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
