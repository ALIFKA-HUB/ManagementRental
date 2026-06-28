import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.lightSurface,
          error: AppColors.error,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.heading.copyWith(color: AppColors.textPrimaryLight),
          titleLarge: AppTypography.subHeading.copyWith(color: AppColors.textPrimaryLight),
          bodyLarge: AppTypography.body.copyWith(color: AppColors.textPrimaryLight),
          bodyMedium: AppTypography.body.copyWith(color: AppColors.textSecondaryLight),
          labelSmall: AppTypography.caption.copyWith(color: AppColors.textSecondaryLight),
        ),
        dividerColor: AppColors.divider,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.darkSurface,
          error: AppColors.error,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.heading.copyWith(color: AppColors.textPrimaryDark),
          titleLarge: AppTypography.subHeading.copyWith(color: AppColors.textPrimaryDark),
          bodyLarge: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
          bodyMedium: AppTypography.body.copyWith(color: AppColors.textSecondaryDark),
          labelSmall: AppTypography.caption.copyWith(color: AppColors.textSecondaryDark),
        ),
        dividerColor: AppColors.divider,
      );
}
