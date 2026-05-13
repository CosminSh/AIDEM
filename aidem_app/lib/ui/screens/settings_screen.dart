import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/global_providers.dart';
import '../../services/model_setup_service.dart';
import '../widgets/brand_mark.dart';
import '../widgets/tactical_container.dart';
import '../widgets/voice_diagnostics_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(modelSetupServiceProvider);
    final soundState = ref.watch(uiSoundSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: 0,
          ),
        ),
      ),
      body: AidemBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel(label: 'Model'),
                    const SizedBox(height: 12),
                    TacticalContainer(
                      padding: const EdgeInsets.all(20),
                      showGlow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AidemBrandMark(
                                size: 42,
                                padding: EdgeInsets.all(5),
                                glow: false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current model',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    Text(
                                      setupState.status == ModelStatus.ready
                                          ? 'Gemma 4-E2B-IT active'
                                          : 'No active model',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (setupState.status == ModelStatus.downloading) ...[
                            const LinearProgressIndicator(
                              color: AppColors.brandAi,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              setupState.statusMessage,
                              style: GoogleFonts.inter(
                                color: AppColors.brandAi,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(type: FileType.any);
                                  if (result != null &&
                                      result.files.single.path != null) {
                                    ref
                                        .read(
                                          modelSetupServiceProvider.notifier,
                                        )
                                        .installFromLocalFile(
                                          result.files.single.path!,
                                        );
                                  }
                                },
                                icon: const Icon(
                                  Icons.folder_open_outlined,
                                  size: 18,
                                ),
                                label: const Text('Change LLM model file'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SectionLabel(label: 'Voice'),
                    const SizedBox(height: 12),
                    const VoiceDiagnosticsPanel(),
                    const SizedBox(height: 32),
                    const SectionLabel(label: 'Interface'),
                    const SizedBox(height: 12),
                    TacticalContainer(
                      padding: EdgeInsets.zero,
                      showGlow: false,
                      child: SwitchListTile(
                        secondary: const Icon(
                          Icons.volume_up_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        title: Text(
                          'Interface sounds',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        subtitle: const Text(
                          'Very subtle tap feedback for app controls.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: soundState.enabled,
                        activeThumbColor: AppColors.brandAi,
                        onChanged: (value) => ref
                            .read(uiSoundSettingsProvider.notifier)
                            .setEnabled(value),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SectionLabel(label: 'Permissions'),
                    const SizedBox(height: 12),
                    TacticalContainer(
                      padding: EdgeInsets.zero,
                      showGlow: false,
                      child: Column(
                        children: [
                          _buildPermissionTile(
                            Icons.mic_none_rounded,
                            'Microphone',
                            'Authorized',
                            AppColors.brandAi,
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildPermissionTile(
                            Icons.camera_alt_outlined,
                            'Camera',
                            'Authorized',
                            AppColors.brandAi,
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildPermissionTile(
                            Icons.location_on_outlined,
                            'GPS',
                            'Authorized',
                            AppColors.brandAi,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SectionLabel(label: 'About AIDEM'),
                    const SizedBox(height: 12),
                    TacticalContainer(
                      padding: const EdgeInsets.all(20),
                      showGlow: false,
                      child: Column(
                        children: [
                          _buildInfoRow('Version', '1.0.0'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Build ID', '5b314108544d'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Storage', 'Local device'),
                        ],
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

  Widget _buildPermissionTile(
    IconData icon,
    String title,
    String status,
    Color statusColor,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      trailing: Text(
        status,
        style: GoogleFonts.inter(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
