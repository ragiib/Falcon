import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class FalconTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidian,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyanGlow,
        secondary: AppColors.electricBlue,
        surface: AppColors.darkBackground,
        error: AppColors.electricBlue,
      ),
      textTheme: GoogleFonts.shareTechMonoTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.shareTechMono(
          color: AppColors.cyanGlow,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
        displayMedium: GoogleFonts.shareTechMono(
          color: AppColors.cyanGlow,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
        bodyLarge: GoogleFonts.shareTechMono(
          color: AppColors.textPrimary,
          fontSize: 14,
          letterSpacing: 1.0,
        ),
        bodyMedium: GoogleFonts.shareTechMono(
          color: AppColors.textSecondary,
          fontSize: 11,
          letterSpacing: 1.0,
        ),
        bodySmall: GoogleFonts.shareTechMono(
          color: AppColors.textSecondary,
          fontSize: 9,
          letterSpacing: 1.2,
        ),
        labelMedium: GoogleFonts.shareTechMono(
          color: AppColors.cyanGlow,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        labelSmall: GoogleFonts.shareTechMono(
          color: AppColors.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
      useMaterial3: true,
    );
  }
}
