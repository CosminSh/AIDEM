import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/global_providers.dart';
import '../../services/model_setup_service.dart';
import 'home_screen.dart';

class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Check model status on launch
    Future.microtask(() async {
      final setupNotifier = ref.read(modelSetupServiceProvider.notifier);
      final isInstalled = await setupNotifier.checkIfInstalled();
      if (isInstalled && mounted) {
        _goToHome();
      }
    });
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(modelSetupServiceProvider);

    // Auto-navigate when model becomes ready
    if (setupState.status == ModelStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToHome());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Title
            const Icon(Icons.psychology_outlined, color: AppColors.accentBlue, size: 56),
            const SizedBox(height: 24),
            const Text(
              'First-Time Setup',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Survival AId needs to download the Gemma AI model once. '
              'After this, the app works fully offline — no internet required.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 8),
            // Model details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.memory, label: 'Model', value: 'Gemma 3 1B (Google)'),
                  SizedBox(height: 8),
                  _InfoRow(icon: Icons.storage, label: 'Size', value: '~1.2 GB'),
                  SizedBox(height: 8),
                  _InfoRow(icon: Icons.wifi_off, label: 'After install', value: '100% offline'),
                  SizedBox(height: 8),
                  _InfoRow(icon: Icons.speed, label: 'Inference', value: 'GPU-accelerated'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Status / Progress
            if (setupState.status == ModelStatus.downloading) ...[
              Text(
                setupState.statusMessage,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: setupState.downloadProgress,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(setupState.downloadProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],

            if (setupState.status == ModelStatus.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Error: ${setupState.errorMessage}',
                  style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
                ),
              ),

            const SizedBox(height: 24),

            // Token Input Field
            if (setupState.status != ModelStatus.downloading) ...[
              const Text(
                'HuggingFace Token (Required for gated models)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'hf_...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    borderSide: const BorderSide(color: AppColors.accentBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 8),

            // Download Button
            if (setupState.status != ModelStatus.downloading) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final token = _tokenController.text.trim();
                    ref.read(modelSetupServiceProvider.notifier).downloadAndInstall(
                      huggingFaceToken: token.isNotEmpty ? token : null,
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text(
                    'DOWNLOAD & INSTALL GEMMA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radius),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Secondary Options (Pick File / Link)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                        );
                        if (result != null && result.files.single.path != null) {
                          ref.read(modelSetupServiceProvider.notifier).installFromLocalFile(
                            result.files.single.path!,
                          );
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('SELECT LOCAL FILE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('https://huggingface.co/litert-community/Gemma3-1B-IT')),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('VISIT MODEL PAGE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              // Skip option (falls back to adaptive mock)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _goToHome,
                  child: const Text(
                    'Skip for now (use offline logic)',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentBlue, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
