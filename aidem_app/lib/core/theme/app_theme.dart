import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF02090B);
  static const Color backgroundAlt = Color(0xFF061012);
  static const Color surface = Color(0xFF0B1719);
  static const Color surfaceElevated = Color(0xFF102326);
  static const Color surfaceMuted = Color(0xFF061113);
  static const Color surfaceHover = Color(0xFF142C2F);

  static const Color brandAi = Color(0xFF27D3C3);
  static const Color accentOrange = Color(0xFFE69535);
  static const Color accentBlue = Color(0xFF5AA9FF);
  static const Color accentRed = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFFF4FAFA);
  static const Color textSecondary = Color(0xFF8DA7AA);
  static const Color textMuted = Color(0xFF51676C);
  static const Color success = brandAi;
  static const Color warning = accentOrange;

  static const Color border = Color(0xFF173A3C);
  static const Color borderSoft = Color(0xFF0D2426);
  static const Color emeraldGlow = Color(0x3327D3C3);
  static const Color shadow = Color(0x66000000);

  static const double radius = 18.0;
  static const double radiusLarge = 30.0;
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.brandAi,
    colorScheme: ColorScheme.dark(
      primary: AppColors.brandAi,
      secondary: AppColors.accentBlue,
      surface: AppColors.surface,
      error: AppColors.accentRed,
      onPrimary: Colors.black,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    ),
    textTheme:
        GoogleFonts.interTextTheme(
          const TextTheme(
            headlineLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
            headlineMedium: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
            titleLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
            bodyLarge: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.55,
              letterSpacing: 0,
            ),
            bodyMedium: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ).copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
          displayMedium: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
          displaySmall: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
          labelSmall: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandAi,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        hoverColor: AppColors.surfaceHover,
        highlightColor: AppColors.surfaceHover,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.brandAi, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
      ),
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevated,
      disabledColor: AppColors.surfaceMuted,
      selectedColor: AppColors.brandAi.withValues(alpha: 0.14),
      secondarySelectedColor: AppColors.brandAi.withValues(alpha: 0.18),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      secondaryLabelStyle: const TextStyle(color: AppColors.brandAi),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      contentTextStyle: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}
