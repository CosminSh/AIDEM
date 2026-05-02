import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';

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
                onPressed: () => onSelected(branch),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  branch.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
