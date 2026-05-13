import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ui_sound_service.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const MicButton({super.key, required this.isListening, required this.onTap});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    if (widget.isListening) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        UiSoundService.toggle();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isListening
                  ? AppColors.accentRed
                  : AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isListening
                    ? AppColors.accentRed
                    : AppColors.border,
              ),
              boxShadow: widget.isListening
                  ? [
                      BoxShadow(
                        color: AppColors.accentRed.withOpacity(
                          0.3 * _controller.value,
                        ),
                        blurRadius: 15 * _controller.value,
                        spreadRadius: 8 * _controller.value,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              widget.isListening ? Icons.mic : Icons.mic_none,
              color: widget.isListening ? Colors.white : AppColors.textPrimary,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
