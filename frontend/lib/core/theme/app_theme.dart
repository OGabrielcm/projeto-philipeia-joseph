import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      surface:   AppColors.bgPrimary,
      primary:   AppColors.accent,
      onPrimary: AppColors.accentText,
      error:     AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgSecondary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgTertiary,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentText,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderColor),
    textTheme: const TextTheme(
      bodyLarge:   TextStyle(color: AppColors.textPrimary),
      bodyMedium:  TextStyle(color: AppColors.textSecondary),
      bodySmall:   TextStyle(color: AppColors.textMuted),
      titleLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
