import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/global_providers.dart';
import '../../services/model_setup_service.dart';
import '../../services/ui_sound_service.dart';
import '../navigation/app_routes.dart';
import '../widgets/brand_mark.dart';
import '../widgets/model_recommendation_card.dart';
import '../widgets/tactical_container.dart';
import 'home_screen.dart';

class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final setupNotifier = ref.read(modelSetupServiceProvider.notifier);
      final isInstalled = await setupNotifier.checkIfInstalled();
      if (isInstalled && mounted) {
        _goToHome();
      }
    });
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(polishedRoute(const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(modelSetupServiceProvider);

    if (setupState.status == ModelStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToHome());
    }

    return Scaffold(
      body: AidemBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AidemBrandMark(size: 58, padding: EdgeInsets.all(8)),
                    const SizedBox(height: 24),
                    Text(
                      'First-Time Setup',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Download the recommended Gemma LiteRT file, then select it here once. After setup, AIDEM can run fully offline on this device.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SetupChecklist(state: setupState),
                    const SizedBox(height: 14),
                    const ModelRecommendationCard(),
                    const SizedBox(height: 14),
                    TacticalContainer(
                      padding: const EdgeInsets.all(18),
                      showGlow: false,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.psychology,
                            label: 'Model',
                            value: 'Gemma 4 E2B IT LiteRT',
                          ),
                          SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.list_alt,
                            label: 'Size',
                            value: '~2.6 GB for the standard .litertlm file',
                          ),
                          SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.airplanemode_active,
                            label: 'After install',
                            value: 'Offline inference',
                          ),
                          SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.speed,
                            label: 'Runtime',
                            value: 'On-device reasoning',
                          ),
                        ],
                      ),
                    ),
                    if (setupState.status == ModelStatus.downloading) ...[
                      const SizedBox(height: 24),
                      _DownloadProgress(state: setupState),
                    ],
                    if (setupState.status == ModelStatus.error) ...[
                      const SizedBox(height: 18),
                      TacticalContainer(
                        showGlow: false,
                        borderColor: AppColors.accentRed.withValues(
                          alpha: 0.32,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.accentRed,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The model was not installed. Select the downloaded .litertlm file, or skip for now and use protocol guidance without local AI.\n\n${setupState.errorMessage}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (setupState.status != ModelStatus.downloading) ...[
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            UiSoundService.confirm();
                            try {
                              final result = await FilePicker.platform
                                  .pickFiles(type: FileType.any);
                              if (result != null &&
                                  result.files.single.path != null) {
                                ref
                                    .read(modelSetupServiceProvider.notifier)
                                    .installFromLocalFile(
                                      result.files.single.path!,
                                    );
                              }
                            } catch (e) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('File picker error: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.folder_open_outlined),
                          label: const Text('Select downloaded model file'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          key: const ValueKey('skip_model_setup'),
                          onPressed: () {
                            UiSoundService.tap();
                            _goToHome();
                          },
                          child: const Text('Skip for now'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  final ModelSetupState state;

  const _DownloadProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    return TacticalContainer(
      showGlow: false,
      borderColor: AppColors.accentBlue.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.accentBlue,
                  strokeWidth: 2.4,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.statusMessage,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          if (state.downloadProgress > 0) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: state.downloadProgress,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentBlue,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(state.downloadProgress * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupChecklist extends StatelessWidget {
  final ModelSetupState state;

  const _SetupChecklist({required this.state});

  @override
  Widget build(BuildContext context) {
    final selected =
        state.status == ModelStatus.downloading ||
        state.status == ModelStatus.ready;
    final verified = state.status == ModelStatus.ready;

    return TacticalContainer(
      padding: const EdgeInsets.all(16),
      showGlow: false,
      borderColor: AppColors.brandAi.withValues(alpha: 0.22),
      child: Column(
        children: [
          _SetupStep(
            index: 1,
            label: 'Download Gemma LiteRT',
            detail: 'Open the recommended model page and download the file.',
            done: true,
          ),
          const SizedBox(height: 12),
          _SetupStep(
            index: 2,
            label: 'Select the downloaded file',
            detail: 'AIDEM copies the model into local app storage.',
            done: selected,
            active: !selected,
          ),
          const SizedBox(height: 12),
          _SetupStep(
            index: 3,
            label: 'Verify offline readiness',
            detail: 'Local AI becomes available after installation.',
            done: verified,
            active: selected && !verified,
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final int index;
  final String label;
  final String detail;
  final bool done;
  final bool active;

  const _SetupStep({
    required this.index,
    required this.label,
    required this.detail,
    this.done = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.brandAi
        : active
        ? AppColors.accentBlue
        : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, color: color, size: 17)
                : Text(
                    '$index',
                    style: GoogleFonts.spaceGrotesk(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentBlue, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
