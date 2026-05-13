import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/gps_service.dart';
import '../../services/rescue_script_service.dart';
import '../widgets/tactical_container.dart';

class RescueScriptScreen extends StatelessWidget {
  final GpsCoordinates coords;
  final String emergencyNumber;

  const RescueScriptScreen({
    super.key,
    required this.coords,
    required this.emergencyNumber,
  });

  @override
  Widget build(BuildContext context) {
    final scriptService = RescueScriptService();
    final script = scriptService.generateScript(
      coords: coords,
      emergencyNumber: emergencyNumber,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Script"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AidemBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppColors.radius),
                  border: Border.all(
                    color: AppColors.accentRed.withOpacity(0.34),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: AppColors.accentRed),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Read this to the dispatcher",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TacticalContainer(
                padding: const EdgeInsets.all(22),
                borderColor: AppColors.accentRed.withOpacity(0.26),
                showGlow: false,
                child: SelectableText(
                  script,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  // Copy to clipboard logic would go here
                },
                icon: const Icon(Icons.copy),
                label: const Text("Copy coordinates"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "I have spoken to rescuers",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
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
