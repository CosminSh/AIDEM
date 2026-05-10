import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/tactical_container.dart';
import 'home_screen.dart';

class OnboardingDisclaimerScreen extends StatelessWidget {
  const OnboardingDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AidemBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentOrange.withOpacity(0.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.accentOrange,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Readiness and Legal Notice',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _buildPoint(
                      'Not a medical professional',
                      'AIDEM is an offline decision support tool based on established first-aid protocols. It is not a substitute for professional medical care or clinical judgment.',
                      Icons.medical_services_outlined,
                    ),
                    _buildPoint(
                      'Contact emergency services first',
                      'Always attempt to reach emergency services (112/911) via cellular, satellite, or radio before relying on AIDEM.',
                      Icons.settings_input_antenna_rounded,
                    ),
                    _buildPoint(
                      'Offline architecture',
                      'All medical reasoning and data processing occur locally on this device. No data is transmitted to external servers.',
                      Icons.vibration_outlined,
                    ),
                    const SizedBox(height: 34),
                    ElevatedButton(
                      key: const ValueKey('accept_disclaimer'),
                      onPressed: () => _handleAccept(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        'Accept and continue',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'By proceeding, you agree to use AIDEM at your own risk in extreme environments.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequestedPermissions =
        prefs.getBool('has_requested_permissions') ?? false;

    if (!hasRequestedPermissions) {
      if (context.mounted) {
        final granted = await _showPermissionDialog(context);
        if (granted) {
          await prefs.setBool('has_requested_permissions', true);
        }
      }
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusLarge),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
            title: Text(
              "System Access",
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "AIDEM uses these permissions for hands-free logging, photos, and location sharing.",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _buildPermissionItem(
                  Icons.mic_none_rounded,
                  "MICROPHONE",
                  "For voice commands and hands-free medical logging.",
                ),
                _buildPermissionItem(
                  Icons.camera_alt_outlined,
                  "CAMERA",
                  "For visual injury assessment and environment scanning.",
                ),
                _buildPermissionItem(
                  Icons.location_on_outlined,
                  "GPS",
                  "For emergency coordinate broadcasting.",
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "SKIP",
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await [
                    Permission.microphone,
                    Permission.camera,
                    Permission.location,
                  ].request();
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  "Authorize all",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildPermissionItem(IconData icon, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandAi, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TacticalContainer(
        padding: const EdgeInsets.all(20),
        showGlow: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandAi, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
