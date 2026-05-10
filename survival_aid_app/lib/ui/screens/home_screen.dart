import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/global_providers.dart';
import '../widgets/emergency_button.dart';
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AIDEM',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Offline Emergency Assistant',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const StatusPill(
                              icon: Icons.sensors_rounded,
                              label: 'Ready',
                              color: AppColors.brandAi,
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.settings_outlined,
                                size: 20,
                              ),
                              tooltip: 'Settings',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Center(
                      child: TacticalContainer(
                        showGlow: false,
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                        child: Column(
                          children: [
                            EmergencyButton(
                              key: const ValueKey('start_emergency'),
                              onPressed: () async {
                                await ref
                                    .read(sessionProvider.notifier)
                                    .startEmergency();
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ActiveSessionScreen(),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Local protocols, location tools, and AI guidance stay available offline.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            if (session.isEmergencyActive &&
                                session.currentSessionId != null) ...[
                              const SizedBox(height: 18),
                              _buildResumeButton(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    const SectionLabel(label: 'Operational Modes'),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 560;
                        final cards = [
                          _buildModeCard(
                            icon: Icons.school_outlined,
                            title: 'Practice',
                            desc: 'Run a simulated emergency',
                            color: AppColors.accentBlue,
                            onTap: () async {
                              await ref
                                  .read(sessionProvider.notifier)
                                  .startPractice();
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ActiveSessionScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildModeCard(
                            icon: Icons.map_outlined,
                            title: 'Location',
                            desc: 'Share coordinates in session',
                            color: AppColors.brandAi,
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
                        ];

                        if (compact) {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 12),
                              cards[1],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    if (session.sessionHistory.isNotEmpty) ...[
                      SectionLabel(
                        label: 'Session History',
                        trailing: Text(
                          '${session.sessionHistory.length} total',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: session.sessionHistory.length,
                        itemBuilder: (context, index) {
                          final s = session.sessionHistory[index];
                          return _buildSessionLogItem(s);
                        },
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

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusLarge),
      child: TacticalContainer(
        padding: const EdgeInsets.all(18),
        showGlow: false,
        borderColor: color.withOpacity(0.22),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.22)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ActiveSessionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
        label: const Text('Resume active session'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandAi,
          side: BorderSide(color: AppColors.brandAi.withOpacity(0.45)),
        ),
      ),
    );
  }

  Widget _buildSessionLogItem(dynamic s) {
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(0.2)),
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
            await ref.read(sessionProvider.notifier).resumeSession(s.id);
            if (!mounted) {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActiveSessionScreen(),
              ),
            );
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
}
