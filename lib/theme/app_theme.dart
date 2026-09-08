import 'package:flutter/material.dart';

class AppColors {
  // LIGHT
  static const lightText = Color(0xFF16251E);
  static const lightBackground = Color(0xFFF5F7F2);
  static const lightForeground = Color(0xFF16251E);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF1E6F50);
  static const lightPrimaryForeground = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFFE8F0E7);
  static const lightSecondaryForeground = Color(0xFF1E6F50);
  static const lightMuted = Color(0xFFEDF1EB);
  static const lightMutedForeground = Color(0xFF7A887F);
  static const lightAccent = Color(0xFFF4C96B);
  static const lightAccentForeground = Color(0xFF624919);
  static const lightDestructive = Color(0xFFC95252);
  static const lightDestructiveForeground = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFDCE5DC);
  static const lightInput = Color(0xFFE3EAE2);
  static const lightIncome = Color(0xFF238A62);
  static const lightExpense = Color(0xFFC95252);
  static const lightNavy = Color(0xFF244E5B);
  static const lightSoftGold = Color(0xFFFFF2D1);

  // DARK
  static const darkText = Color(0xFFF1F6F0);
  static const darkBackground = Color(0xFF111A16);
  static const darkForeground = Color(0xFFF1F6F0);
  static const darkCard = Color(0xFF1B2821);
  static const darkPrimary = Color(0xFF82D1A6);
  static const darkPrimaryForeground = Color(0xFF132119);
  static const darkSecondary = Color(0xFF24372D);
  static const darkSecondaryForeground = Color(0xFFBFEACD);
  static const darkMuted = Color(0xFF233229);
  static const darkMutedForeground = Color(0xFF9BAEA1);
  static const darkAccent = Color(0xFFF4C96B);
  static const darkAccentForeground = Color(0xFF3E2E0F);
  static const darkDestructive = Color(0xFFE47A7A);
  static const darkDestructiveForeground = Color(0xFF291313);
  static const darkBorder = Color(0xFF304339);
  static const darkInput = Color(0xFF2A3B31);
  static const darkIncome = Color(0xFF82D1A6);
  static const darkExpense = Color(0xFFE47A7A);
  static const darkNavy = Color(0xFF8FC8D4);
  static const darkSoftGold = Color(0xFF40351D);

  static const radius = 22.0;
}

ThemeData lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightPrimaryForeground,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightSecondaryForeground,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightForeground,
      error: AppColors.lightDestructive,
      onError: AppColors.lightDestructiveForeground,
      outline: AppColors.lightBorder,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: AppColors.lightPrimary,
          width: 1.5,
        ),
      ),
    ),
  );
}

ThemeData darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkPrimaryForeground,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkSecondaryForeground,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkForeground,
      error: AppColors.darkDestructive,
      onError: AppColors.darkDestructiveForeground,
      outline: AppColors.darkBorder,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: AppColors.darkPrimary,
          width: 1.5,
        ),
      ),
    ),
  );
}