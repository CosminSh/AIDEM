import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Calm & Clear)
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceHover = Color(0xFF334155);
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  
  // Accents
  static const Color accentRed = Color(0xFFEF4444);    // Critical/Emergency
  static const Color accentBlue = Color(0xFF3B82F6);   // User actions
  static const Color success = Color(0xFF10B981);      // GPS ready / Status
  static const Color warning = Color(0xFFF59E0B);      // GPS acquiring
  
  // Borders
  static const Color border = Color(0xFF334155);
  
  // Radii
  static const double radius = 16.0;
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.accentBlue,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 28,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),
    // ... Additional theme configurations
  );
}
