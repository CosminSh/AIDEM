import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'core/theme/app_theme.dart';
import 'providers/global_providers.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_gemma — no HuggingFace token needed for public models
  FlutterGemma.initialize();

  runApp(const ProviderScope(child: AidemApp()));
}

class AidemApp extends ConsumerWidget {
  const AidemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(uiSoundSettingsProvider);

    return MaterialApp(
      title: 'AIDEM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OnboardingDisclaimerScreen(),
    );
  }
}
