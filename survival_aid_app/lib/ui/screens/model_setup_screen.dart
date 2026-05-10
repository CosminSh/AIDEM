import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/global_providers.dart';
import '../../services/model_setup_service.dart';
import '../widgets/tactical_container.dart';
import 'home_screen.dart';

class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  final TextEditingController _tokenController = TextEditingController();

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

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
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
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentBlue.withOpacity(0.24),
                        ),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: AppColors.accentBlue,
                        size: 30,
                      ),
                    ),
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
                      'Install the Gemma model once. After setup, AIDEM can run fully offline on this device.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TacticalContainer(
                      padding: const EdgeInsets.all(18),
                      showGlow: false,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.psychology,
                            label: 'Model',
                            value: 'Gemma 4 E2B',
                          ),
                          SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.list_alt,
                            label: 'Size',
                            value: '~2.1 GB',
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
                      Text(
                        'Error: ${setupState.errorMessage}',
                        style: const TextStyle(
                          color: AppColors.accentRed,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (setupState.status != ModelStatus.downloading) ...[
                      const SizedBox(height: 26),
                      const SectionLabel(label: 'HuggingFace Token'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tokenController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(hintText: 'hf_...'),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final token = _tokenController.text.trim();
                            ref
                                .read(modelSetupServiceProvider.notifier)
                                .downloadAndInstall(
                                  huggingFaceToken: token.isNotEmpty
                                      ? token
                                      : null,
                                );
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download and install Gemma'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 430;
                          final buttons = [
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
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
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Select local file'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(
                                  'https://huggingface.co/google/gemma-4-2b-it-lite-rt-gguf',
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Model page'),
                            ),
                          ];

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buttons[0],
                                const SizedBox(height: 12),
                                buttons[1],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: buttons[0]),
                              const SizedBox(width: 12),
                              Expanded(child: buttons[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          key: const ValueKey('skip_model_setup'),
                          onPressed: _goToHome,
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
      borderColor: AppColors.accentBlue.withOpacity(0.28),
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
