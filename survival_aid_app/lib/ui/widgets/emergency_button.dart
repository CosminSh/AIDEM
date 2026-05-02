import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EmergencyButton extends StatefulWidget {
  final VoidCallback onPressed;

  const EmergencyButton({super.key, required this.onPressed});

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
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentRed.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "I NEED\nHELP",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
