import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ui_sound_service.dart';
import '../navigation/app_routes.dart';
import '../widgets/brand_mark.dart';
import '../widgets/tactical_container.dart';
import 'home_screen.dart';

class OnboardingDisclaimerScreen extends StatelessWidget {
  const OnboardingDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AidemBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeight = constraints.maxHeight < 760;
              final iconSize = compactHeight ? 52.0 : 72.0;
              final contentMaxWidth = compactHeight ? 620.0 : 680.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: compactHeight ? 14 : 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: AidemBrandMark(
                            size: iconSize,
                            padding: EdgeInsets.all(compactHeight ? 8 : 10),
                          ),
                        ),
                        SizedBox(height: compactHeight ? 14 : 24),
                        Text(
                          'Readiness and Legal Notice',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: compactHeight ? 22 : 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: compactHeight ? 4 : 8),
                        const Text(
                          'Offline emergency guidance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.brandAi,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: compactHeight ? 20 : 34),
                        _buildPoint(
                          'Not a medical professional',
                          'AIDEM is an offline decision support tool based on established first-aid protocols. It is not a substitute for professional medical care or clinical judgment.',
                          Icons.medical_services_outlined,
                          compact: compactHeight,
                        ),
                        _buildPoint(
                          'Contact emergency services first',
                          'Always attempt to reach emergency services (112/911) via cellular, satellite, or radio before relying on AIDEM.',
                          Icons.settings_input_antenna_rounded,
                          compact: compactHeight,
                        ),
                        _buildPoint(
                          'Offline architecture',
                          'All medical reasoning and data processing occur locally on this device. No data is transmitted to external servers.',
                          Icons.vibration_outlined,
                          compact: compactHeight,
                        ),
                        SizedBox(height: compactHeight ? 14 : 24),
                        ElevatedButton(
                          key: const ValueKey('accept_disclaimer'),
                          onPressed: () {
                            UiSoundService.confirm();
                            _handleAccept(context);
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            padding: EdgeInsets.symmetric(
                              vertical: compactHeight ? 14 : 18,
                            ),
                          ),
                          child: Text(
                            'Accept and continue',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'By proceeding, you agree to use AIDEM at your own risk in extreme environments.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
      Navigator.pushReplacement(context, polishedRoute(const HomeScreen()));
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

  Widget _buildPoint(
    String title,
    String description,
    IconData icon, {
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 12 : 20),
      child: TacticalContainer(
        padding: EdgeInsets.all(compact ? 14 : 20),
        showGlow: false,
        borderRadius: compact ? AppColors.radius : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandAi, size: compact ? 20 : 24),
            SizedBox(width: compact ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: compact ? 12 : 13,
                      height: compact ? 1.35 : 1.6,
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
