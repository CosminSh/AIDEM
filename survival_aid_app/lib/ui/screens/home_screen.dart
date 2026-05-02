import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/emergency_button.dart';
import '../../providers/global_providers.dart';
import 'active_session_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sessionProvider.notifier).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      body: Stack(
        children: [
          // GPS Status Indicator (Top Right)
          const Positioned(
            top: 60,
            right: 24,
            child: Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                SizedBox(width: 8),
                Text(
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
          
          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                    EmergencyButton(
                      onPressed: () {
                        ref.read(sessionProvider.notifier).startEmergency();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ActiveSessionScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(sessionProvider.notifier).startPractice();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActiveSessionScreen()),
                          );
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
