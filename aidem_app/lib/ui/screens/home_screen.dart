import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/demo_scenario.dart';
import '../../providers/global_providers.dart';
import '../../providers/session_provider.dart';
import '../../services/llm_service.dart';
import '../../services/model_setup_service.dart';
import '../../services/ui_sound_service.dart';
import '../navigation/app_routes.dart';
import '../widgets/brand_mark.dart';
import '../widgets/emergency_button.dart';
import '../widgets/model_recommendation_card.dart';
import '../widgets/tactical_container.dart';
import 'active_session_screen.dart';
import 'model_setup_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(sessionProvider.notifier).initialize();

      final setupNotifier = ref.read(modelSetupServiceProvider.notifier);
      final isInstalled = await setupNotifier.checkIfInstalled();
      if (!isInstalled && mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ModelSetupScreen()));
      } else {
        final llm = ref.read(llmServiceProvider.notifier);
        await llm.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      body: AidemBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final horizontalPadding = wide
                  ? 48.0
                  : constraints.maxWidth < 380
                  ? 12.0
                  : constraints.maxWidth < 520
                  ? 16.0
                  : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  wide ? 26 : 22,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 900 : 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: wide ? 620 : double.infinity,
                            ),
                            child: _buildHeader(context),
                          ),
                        ),
                        SizedBox(height: wide ? 24 : 28),
                        if (wide)
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                children: [
                                  _buildEmergencyPanel(session, isWide: true),
                                  const SizedBox(height: 14),
                                  _buildDesktopActionDock(session),
                                  const SizedBox(height: 14),
                                  _buildOfflineReadinessCard(),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          _buildEmergencyPanel(session, isWide: false),
                          const SizedBox(height: 14),
                          _buildDesktopActionDock(session, compact: true),
                          const SizedBox(height: 14),
                          _buildOfflineReadinessCard(),
                        ],
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

  Widget _buildHeader(BuildContext context) {
    final setupState = ref.watch(modelSetupServiceProvider);
    final llmState = ref.watch(llmServiceProvider);
    final ready =
        setupState.status == ModelStatus.ready &&
        llmState.status == LlmStatus.ready;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AidemBrandMark(
                    size: 36,
                    padding: EdgeInsets.all(4),
                    glow: false,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AIDEM',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusPill(
              icon: ready
                  ? Icons.verified_user_outlined
                  : Icons.info_outline_rounded,
              label: ready ? 'Ready' : 'Protocol',
              color: ready ? AppColors.brandAi : AppColors.brandAi,
            ),
            const SizedBox(width: 8),
            _HeaderIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onTap: () {
                Navigator.push(context, polishedRoute(const SettingsScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startEmergencySession() async {
    await ref.read(sessionProvider.notifier).startEmergency();
    if (!mounted) {
      return;
    }
    Navigator.push(context, polishedRoute(const ActiveSessionScreen()));
  }

  Future<void> _startPracticeSession() async {
    await ref.read(sessionProvider.notifier).startPractice();
    if (!mounted) {
      return;
    }
    Navigator.push(context, polishedRoute(const ActiveSessionScreen()));
  }

  Widget _buildEmergencyPanel(SessionState session, {required bool isWide}) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, isWide ? 18 : 16, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Emergency session',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Designed for local, no-signal guidance.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: isWide ? 34 : 28),
          Center(
            child: EmergencyButton(
              key: const ValueKey('start_emergency'),
              size: isWide ? 236 : 212,
              onPressed: _startEmergencySession,
            ),
          ),
          SizedBox(height: isWide ? 32 : 24),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: const [
                _HomeMetric(
                  icon: Icons.fact_check_outlined,
                  label: 'Protocols',
                  value: '166',
                  color: AppColors.brandAi,
                ),
                _HomeMetric(
                  icon: Icons.memory_rounded,
                  label: 'Edge AI',
                  value: 'Local',
                  color: AppColors.accentBlue,
                ),
                _HomeMetric(
                  icon: Icons.location_on_outlined,
                  label: 'Rescue',
                  value: 'GPS',
                  color: AppColors.accentOrange,
                ),
              ],
            ),
          ),
          if (session.isEmergencyActive &&
              session.currentSessionId != null) ...[
            const SizedBox(height: 18),
            _buildResumeButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopActionDock(SessionState session, {bool compact = false}) {
    final setupState = ref.watch(modelSetupServiceProvider);
    final llmState = ref.watch(llmServiceProvider);

    return SizedBox(
      width: double.infinity,
      child: TacticalContainer(
        padding: EdgeInsets.all(compact ? 12 : 10),
        showGlow: false,
        borderRadius: 22,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacing = constraints.maxWidth < 360 ? 8.0 : 10.0;
            final columns = constraints.maxWidth >= 520
                ? 3
                : constraints.maxWidth >= 292
                ? 2
                : 1;
            final buttonWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            final buttonHeight = compact ? 52.0 : 48.0;

            return Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _HomeCommandButton(
                  icon: Icons.movie_filter_outlined,
                  label: 'Best demo',
                  color: AppColors.brandAi,
                  width: buttonWidth,
                  height: buttonHeight,
                  onTap: _startBestDemo,
                ),
                _HomeCommandButton(
                  icon: Icons.school_outlined,
                  label: 'Practice',
                  color: AppColors.accentBlue,
                  width: buttonWidth,
                  height: buttonHeight,
                  onTap: _startPracticeSession,
                ),
                _HomeCommandButton(
                  icon: Icons.map_outlined,
                  label: 'Location',
                  color: AppColors.brandAi,
                  width: buttonWidth,
                  height: buttonHeight,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Location sharing is available inside an active session.',
                        ),
                      ),
                    );
                  },
                ),
                _HomeCommandButton(
                  icon: Icons.playlist_play_rounded,
                  label: 'Demos',
                  color: AppColors.accentOrange,
                  width: buttonWidth,
                  height: buttonHeight,
                  onTap: _showDemoScenariosDialog,
                ),
                _HomeCommandButton(
                  icon: Icons.history_rounded,
                  label: 'History ${session.sessionHistory.length}',
                  color: AppColors.textSecondary,
                  width: buttonWidth,
                  height: buttonHeight,
                  onTap: session.sessionHistory.isEmpty
                      ? null
                      : () => _showSessionHistoryDialog(),
                ),
                _HomeCommandButton(
                  icon: _modelButtonIcon(setupState, llmState),
                  label: _modelButtonLabel(setupState, llmState),
                  color: _modelButtonColor(setupState, llmState),
                  width: buttonWidth,
                  height: buttonHeight,
                  onTap: _showModelDialog,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _modelButtonIcon(ModelSetupState setupState, LlmState llmState) {
    if (setupState.status == ModelStatus.downloading ||
        llmState.status == LlmStatus.loading) {
      return Icons.hourglass_top_rounded;
    }
    if (setupState.status != ModelStatus.ready ||
        llmState.status == LlmStatus.error ||
        llmState.status == LlmStatus.mock) {
      return Icons.warning_amber_rounded;
    }
    return Icons.psychology_outlined;
  }

  String _modelButtonLabel(ModelSetupState setupState, LlmState llmState) {
    if (setupState.status == ModelStatus.downloading ||
        llmState.status == LlmStatus.loading) {
      return 'LLM loading';
    }
    if (setupState.status != ModelStatus.ready) {
      return 'No LLM';
    }
    if (llmState.status == LlmStatus.error) {
      return 'LLM error';
    }
    if (llmState.status == LlmStatus.mock) {
      return 'Mock AI';
    }

    final label = setupState.modelLabel.toLowerCase();
    if (label.contains('gemma')) {
      return 'Gemma 4';
    }
    return 'LLM ready';
  }

  Color _modelButtonColor(ModelSetupState setupState, LlmState llmState) {
    if (setupState.status == ModelStatus.downloading ||
        llmState.status == LlmStatus.loading) {
      return AppColors.accentBlue;
    }
    if (setupState.status != ModelStatus.ready ||
        llmState.status == LlmStatus.error ||
        llmState.status == LlmStatus.mock) {
      return AppColors.accentRed;
    }
    return AppColors.brandAi;
  }

  Widget _buildResumeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(context, polishedRoute(const ActiveSessionScreen()));
        },
        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
        label: const Text('Resume active session'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandAi,
          side: BorderSide(color: AppColors.brandAi.withValues(alpha: 0.45)),
        ),
      ),
    );
  }

  Future<void> _openDemoScenario(DemoScenario scenario) async {
    await ref.read(sessionProvider.notifier).startDemoScenario(scenario);
    if (!mounted) {
      return;
    }
    Navigator.push(context, polishedRoute(const ActiveSessionScreen()));
  }

  Future<void> _startBestDemo() async {
    final scenario = demoScenarios.firstWhere(
      (scenario) => scenario.id == 'runner_knee_self_evac',
      orElse: () => demoScenarios.first,
    );
    await _openDemoScenario(scenario);
  }

  Future<void> _showDemoScenariosDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLarge),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SectionLabel(label: 'Demo Scenarios'),
                      const SizedBox(width: 10),
                      const StatusPill(
                        icon: Icons.movie_filter_outlined,
                        label: 'Judge-ready',
                        color: AppColors.brandAi,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: demoScenarios.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final scenario = demoScenarios[index];
                        return _buildDemoScenarioCard(
                          scenario,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _openDemoScenario(scenario);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSessionHistoryDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLarge),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Consumer(
                builder: (context, ref, _) {
                  final history = ref.watch(sessionProvider).sessionHistory;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SectionLabel(
                              label: 'Session History',
                              trailing: Text(
                                '${history.length} total',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No saved sessions yet.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              return _buildSessionLogItem(
                                history[index],
                                closeBeforeOpen: true,
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showModelDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLarge),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Consumer(
                builder: (context, ref, _) {
                  final setupState = ref.watch(modelSetupServiceProvider);
                  final llmState = ref.watch(llmServiceProvider);
                  final color = _modelButtonColor(setupState, llmState);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _modelButtonIcon(setupState, llmState),
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'LLM model',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TacticalContainer(
                        showGlow: setupState.status != ModelStatus.ready,
                        accentColor: color,
                        borderColor: color.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              setupState.modelLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _modelStatusText(setupState, llmState),
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (setupState.activeModelPath != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                setupState.activeModelPath!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const ModelRecommendationCard(compact: true),
                      if (setupState.status == ModelStatus.downloading) ...[
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: setupState.downloadProgress > 0
                              ? setupState.downloadProgress
                              : null,
                          color: AppColors.accentBlue,
                          backgroundColor: AppColors.background,
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              setupState.status == ModelStatus.downloading
                              ? null
                              : _selectModelFile,
                          icon: const Icon(Icons.folder_open_outlined),
                          label: const Text('Select another model file'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _modelStatusText(ModelSetupState setupState, LlmState llmState) {
    if (setupState.status == ModelStatus.downloading) {
      return setupState.statusMessage;
    }
    if (setupState.status != ModelStatus.ready) {
      return 'No local LLM is loaded. AIDEM will use fallback responses until a model is selected.';
    }
    if (llmState.status == LlmStatus.ready) {
      return 'Loaded for offline inference.';
    }
    if (llmState.status == LlmStatus.loading) {
      return 'Initializing model...';
    }
    if (llmState.status == LlmStatus.mock) {
      return 'Fallback mode active. Select or reload a local model.';
    }
    return llmState.errorMessage ?? 'Model failed to initialize.';
  }

  Future<void> _selectModelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;
      await ref
          .read(modelSetupServiceProvider.notifier)
          .installFromLocalFile(filePath);

      final setupState = ref.read(modelSetupServiceProvider);
      if (setupState.status == ModelStatus.ready) {
        await ref.read(llmServiceProvider.notifier).close();
        await ref.read(llmServiceProvider.notifier).init();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(setupState.statusMessage)));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Model picker error: $e')));
    }
  }

  Widget _buildDemoScenarioCard(DemoScenario scenario, {VoidCallback? onTap}) {
    final color = switch (scenario.id) {
      'severe_bleeding_no_kit' => AppColors.accentRed,
      'burn_image_path' => AppColors.accentOrange,
      'hypothermia_exposure' => AppColors.accentBlue,
      _ => AppColors.brandAi,
    };
    final icon = switch (scenario.id) {
      'severe_bleeding_no_kit' => Icons.healing_outlined,
      'burn_image_path' => Icons.local_fire_department_outlined,
      'hypothermia_exposure' => Icons.ac_unit_rounded,
      _ => Icons.hiking_rounded,
    };

    return InkWell(
      onTap: () {
        UiSoundService.tap();
        (onTap ?? () => _openDemoScenario(scenario))();
      },
      borderRadius: BorderRadius.circular(AppColors.radiusLarge),
      child: TacticalContainer(
        padding: const EdgeInsets.all(16),
        showGlow: false,
        borderColor: color.withValues(alpha: 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandAi.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.brandAi.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Text(
                    'DEMO MODE',
                    style: TextStyle(
                      color: AppColors.brandAi,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.play_arrow_rounded, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              scenario.title,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scenario.subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: scenario.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: color.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionLogItem(dynamic s, {bool closeBeforeOpen = false}) {
    final timeAgo = _formatTimeAgo(s.lastUpdated);
    final color = s.isPracticeMode
        ? AppColors.accentBlue
        : AppColors.accentOrange;
    final title = s.situationSummary.isNotEmpty
        ? s.situationSummary
        : 'New session';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TacticalContainer(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        showGlow: false,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(
              s.isPracticeMode
                  ? Icons.school_outlined
                  : Icons.emergency_outlined,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$timeAgo | ${s.chatHistory.length} entries',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Delete session',
            onPressed: () =>
                ref.read(sessionProvider.notifier).deleteSession(s.id),
          ),
          onTap: () async {
            if (closeBeforeOpen) {
              Navigator.of(context).pop();
            }
            await ref.read(sessionProvider.notifier).resumeSession(s.id);
            if (!mounted) {
              return;
            }
            Navigator.push(context, polishedRoute(const ActiveSessionScreen()));
          },
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildOfflineReadinessCard() {
    final setupState = ref.watch(modelSetupServiceProvider);
    final llmState = ref.watch(llmServiceProvider);
    final modelReady =
        setupState.status == ModelStatus.ready &&
        llmState.status == LlmStatus.ready;
    final modelLabel = switch (llmState.status) {
      LlmStatus.ready => 'Local model ready',
      LlmStatus.loading => 'Model initializing',
      LlmStatus.mock => 'Fallback mode labeled',
      LlmStatus.error => 'Protocol fallback active',
    };

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final tight = outerConstraints.maxWidth < 380;

        return TacticalContainer(
          padding: EdgeInsets.all(tight ? 10 : 14),
          showGlow: false,
          borderRadius: 18,
          borderColor: AppColors.brandAi.withValues(alpha: 0.24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    modelReady
                        ? Icons.offline_bolt_rounded
                        : Icons.fact_check_outlined,
                    color: AppColors.brandAi,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    modelReady ? 'Ready' : 'Protocol Ready',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      tight ? 'Local-first' : 'Local-first by design',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final chipWidth = constraints.maxWidth >= 280
                      ? (constraints.maxWidth - 8) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ReadinessPill(
                        icon: Icons.memory_rounded,
                        label: modelLabel,
                        color: modelReady
                            ? AppColors.brandAi
                            : AppColors.accentBlue,
                        width: chipWidth,
                      ),
                      _ReadinessPill(
                        icon: Icons.my_location_outlined,
                        label: 'GPS available',
                        color: AppColors.accentBlue,
                        width: chipWidth,
                      ),
                      _ReadinessPill(
                        icon: Icons.storage_outlined,
                        label: 'Emergency data local',
                        color: AppColors.brandAi,
                        width: chipWidth,
                      ),
                      _ReadinessPill(
                        icon: Icons.signal_cellular_connected_no_internet_4_bar,
                        label: 'No-signal mode',
                        color: AppColors.brandAi,
                        width: chipWidth,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadinessPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double? width;

  const _ReadinessPill({
    required this.icon,
    required this.label,
    required this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCommandButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _HomeCommandButton({
    required this.icon,
    required this.label,
    required this.color,
    this.width = 110,
    this.height = 46,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                UiSoundService.tap();
                onTap!();
              },
        borderRadius: BorderRadius.circular(AppColors.radius),
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: width < 150 ? 8 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: width < 150 ? 16 : 18),
                SizedBox(width: width < 150 ? 6 : 8),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: GoogleFonts.spaceGrotesk(
                      color: color,
                      fontSize: width < 150 ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceMuted.withValues(alpha: 0.72),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            UiSoundService.tap();
            onTap();
          },
          customBorder: const CircleBorder(),
          hoverColor: AppColors.brandAi.withValues(alpha: 0.08),
          highlightColor: AppColors.brandAi.withValues(alpha: 0.12),
          splashColor: AppColors.brandAi.withValues(alpha: 0.14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.brandAi.withValues(alpha: 0.24),
              ),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HomeMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HomeMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
