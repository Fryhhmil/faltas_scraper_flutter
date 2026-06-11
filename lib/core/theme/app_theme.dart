import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      error: AppColors.error,
      onSurface: AppColors.text,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, color: AppColors.text2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.text),
        bodySmall: TextStyle(color: AppColors.text2),
      ),
    );
  }
}
