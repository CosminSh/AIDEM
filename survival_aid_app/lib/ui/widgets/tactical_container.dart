import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TacticalContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showGlow;
  final bool animatePulse;
  final double? borderRadius;
  final Color? borderColor;
  final Color? accentColor;

  const TacticalContainer({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.showGlow = true,
    this.animatePulse = false,
    this.borderRadius,
    this.borderColor,
    this.accentColor,
  });

  @override
  State<TacticalContainer> createState() => _TacticalContainerState();
}

class _TacticalContainerState extends State<TacticalContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animatePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TacticalContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animatePulse != oldWidget.animatePulse) {
      if (widget.animatePulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppColors.radiusLarge,
            ),
            border: Border.all(
              color:
                  widget.borderColor ??
                  (widget.animatePulse
                      ? (widget.accentColor ?? AppColors.brandAi).withOpacity(
                          _pulseAnimation.value,
                        )
                      : AppColors.border),
              width: 1,
            ),
            boxShadow: widget.showGlow
                ? [
                    BoxShadow(
                      color: (widget.accentColor ?? AppColors.brandAi)
                          .withValues(
                            alpha: widget.animatePulse
                                ? _pulseAnimation.value * 0.28
                                : 0.06,
                          ),
                      blurRadius: 42,
                      spreadRadius: -24,
                      offset: const Offset(0, 24),
                    ),
                    const BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 24,
                      spreadRadius: -18,
                      offset: Offset(0, 22),
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class TacticalCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final bool animatePulse;

  const TacticalCard({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.animatePulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return TacticalContainer(
      animatePulse: animatePulse,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title!.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.brandAi,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                      ),
                    ),
                  if (actions != null) Row(children: actions!),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class AidemBackground extends StatelessWidget {
  final Widget child;

  const AidemBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundAlt,
                  AppColors.background,
                  Color(0xFF010607),
                ],
                stops: [0, 0.58, 1],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const SectionLabel({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.brandAi,
        letterSpacing: 0,
      ),
    );

    if (trailing == null) {
      return text;
    }

    return Row(children: [text, const Spacer(), trailing!]);
  }
}

class StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
