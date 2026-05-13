import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';
import '../../services/ui_sound_service.dart';

class OptionsPanel extends StatelessWidget {
  final List<Branch> branches;
  final Function(Branch) onSelected;

  const OptionsPanel({
    super.key,
    required this.branches,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: branches.map((branch) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  UiSoundService.tap();
                  onSelected(branch);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _displayLabel(branch.label),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _displayLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'done') return "I've done this";
    if (normalized == 'got it') return 'Understood';
    if (normalized == 'next') return 'Continue';
    if (normalized == 'done / stable') return 'Stable now';
    return label;
  }
}
