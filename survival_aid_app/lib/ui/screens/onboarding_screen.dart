import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingDisclaimerScreen extends StatelessWidget {
  const OnboardingDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.gavel_rounded, color: AppColors.accentRed, size: 64),
              const SizedBox(height: 32),
              const Text(
                "Important Disclaimer",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPoint(
                        "Not a Substitute for Medical Care",
                        "This app is a decision support tool based on established protocols. It does NOT replace professional medical treatment.",
                      ),
                      _buildPoint(
                        "Call 112/911 First",
                        "Always attempt to contact emergency services before relying solely on this application.",
                      ),
                      _buildPoint(
                        "Protocol Based",
                        "Guidance is derived from Red Cross, WHO, and NASAR wilderness first aid standards.",
                      ),
                      _buildPoint(
                        "Privacy",
                        "All data and AI processing stay 100% offline on your device.",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                key: const ValueKey('accept_disclaimer'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                  ),
                ),
                child: const Text(
                  "I UNDERSTAND & AGREE",
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
