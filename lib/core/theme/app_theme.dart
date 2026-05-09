import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,

    fontFamily: AppTextStyles.fontFamily,

    scaffoldBackgroundColor:
        AppColors.background,

    primaryColor: AppColors.primary,

    visualDensity:
        VisualDensity.adaptivePlatformDensity,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.white,
      error: AppColors.error,
    ),

    // =========================
    // APP BAR
    // =========================
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),

    // =========================
    // CARD
    // =========================
    cardTheme: CardThemeData(
      elevation: 0,

      color: AppColors.white,

      shadowColor: Colors.black12,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppSizes.radiusXL,
        ),
      ),
    ),

    // =========================
    // INPUT
    // =========================
    inputDecorationTheme:
        InputDecorationTheme(
      filled: true,

      fillColor: AppColors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppSizes.radiusL,
        ),

        borderSide: const BorderSide(
          color: AppColors.inputBorder,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppSizes.radiusL,
        ),

        borderSide: const BorderSide(
          color: AppColors.inputBorder,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppSizes.radiusL,
        ),

        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    ),

    // =========================
    // ELEVATED BUTTON
    // =========================
    elevatedButtonTheme:
        ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,

        minimumSize: const Size(
          double.infinity,
          AppSizes.buttonHeight,
        ),

        backgroundColor:
            AppColors.primary,

        foregroundColor:
            AppColors.white,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppSizes.radiusL,
          ),
        ),

        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),

    // =========================
    // TEXT BUTTON
    // =========================
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
            AppColors.primary,
      ),
    ),

    // =========================
    // DIVIDER
    // =========================
    dividerTheme: const DividerThemeData(
      color: AppColors.inputBorder,
      thickness: 1,
    ),

    // =========================
    // TEXT THEME
    // =========================
    textTheme: const TextTheme(
      headlineLarge:
          AppTextStyles.heading1,

      headlineMedium:
          AppTextStyles.heading2,

      bodyMedium:
          AppTextStyles.bodyMedium,
    ),

    // =========================
    // PROGRESS INDICATOR
    // =========================
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),

    // =========================
    // DRAWER
    // =========================
    drawerTheme: const DrawerThemeData(
      backgroundColor:
          AppColors.primary,
    ),
  );
}