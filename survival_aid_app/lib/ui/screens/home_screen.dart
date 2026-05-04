import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/emergency_button.dart';
import '../../providers/global_providers.dart';
import 'active_session_screen.dart';
import 'model_setup_screen.dart';

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

      // Check if Gemma model is installed; route to setup if not
      final setupNotifier = ref.read(modelSetupServiceProvider.notifier);
      final isInstalled = await setupNotifier.checkIfInstalled();
      if (!isInstalled && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ModelSetupScreen()),
        );
      } else {
        // Model is ready — initialize LLM service
        final llm = ref.read(llmServiceProvider.notifier);
        await llm.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      body: Stack(
        children: [
          // GPS Status Indicator (Top Right)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                    const SizedBox(width: 8),
                    const Text(
                      "GPS READY",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Survival AId",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    "Offline Emergency Assistant",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 60),
                  if (!session.isProtocolLoaded)
                    const CircularProgressIndicator(color: AppColors.accentBlue)
                  else ...[
                    if (session.isEmergencyActive && session.currentSessionId != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ActiveSessionScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColors.radius),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                "RESUME ${session.isPracticeMode ? 'PRACTICE' : 'EMERGENCY'}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "OR START NEW",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    EmergencyButton(
                      key: const ValueKey('start_emergency'),
                      onPressed: () async {
                        await ref.read(sessionProvider.notifier).startEmergency();
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActiveSessionScreen()),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () async {
                          await ref.read(sessionProvider.notifier).startPractice();
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ActiveSessionScreen()),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppColors.radius),
                          ),
                        ),
                        child: const Text(
                          "LEARN / PRACTICE",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (session.sessionHistory.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "PREVIOUS CONVERSATIONS",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: session.sessionHistory.length,
                          itemBuilder: (context, index) {
                            final s = session.sessionHistory[index];
                            final timeAgo = _formatTimeAgo(s.lastUpdated);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  s.isPracticeMode ? Icons.school : Icons.emergency,
                                  color: s.isPracticeMode ? AppColors.accentBlue : AppColors.accentRed,
                                ),
                                title: Text(
                                  s.situationSummary.isNotEmpty ? s.situationSummary : "New Conversation",
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  "$timeAgo · ${s.chatHistory.length} messages",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                                  onPressed: () => ref.read(sessionProvider.notifier).deleteSession(s.id),
                                ),
                                onTap: () async {
                                  await ref.read(sessionProvider.notifier).resumeSession(s.id);
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ActiveSessionScreen()),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}
