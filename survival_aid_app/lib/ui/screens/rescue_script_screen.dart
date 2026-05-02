import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/gps_service.dart';
import '../../services/rescue_script_service.dart';

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
      backgroundColor: AppColors.accentRed,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Emergency Script"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "READ THIS TO DISPATCHER",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppColors.radius),
              ),
              child: SelectableText(
                script,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Copy to clipboard logic would go here
              },
              icon: const Icon(Icons.copy),
              label: const Text("COPY COORDINATES"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accentRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radius),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "I HAVE SPOKEN TO RESCUERS - CONTINUE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
