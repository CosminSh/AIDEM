import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_gemma — no HuggingFace token needed for public models
  FlutterGemma.initialize();

  runApp(
    const ProviderScope(
      child: SurvivalAidApp(),
    ),
  );
}

class SurvivalAidApp extends StatelessWidget {
  const SurvivalAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survival AId',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentBlue,
          surface: AppColors.surface,
          error: AppColors.accentRed,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      home: const OnboardingDisclaimerScreen(),
    );
  }
}
