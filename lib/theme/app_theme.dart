import 'package:flutter/material.dart';

/// BhArt brand colors — ported directly from globals.css:
///   --color-terracotta: #E05D3A
///   --color-weaver-blue: #2D3250
///   --color-khadi: #F7F5F0
class AppColors {
  AppColors._();

  static const terracotta = Color(0xFFE05D3A);
  static const weaverBlue = Color(0xFF2D3250);
  static const khadi = Color(0xFFF7F5F0);

  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray900 = Color(0xFF111827);

  static const green600 = Color(0xFF16A34A);
  static const green50 = Color(0xFFF0FDF4);
  static const amber500 = Color(0xFFF59E0B);
  static const blue600 = Color(0xFF2563EB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.khadi,
      fontFamily: 'Inter', // add google_fonts later if you want exact parity with Inter + Noto Sans Devanagari
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.terracotta,
        primary: AppColors.terracotta,
        secondary: AppColors.weaverBlue,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.weaverBlue),
        bodyMedium: TextStyle(color: AppColors.weaverBlue),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
        ),
      ),
    );
  }
}

/// Rounded corner constants matching the Tailwind rounded-3xl / 2xl usage
/// throughout the original app (CatalogCard, AuthForm, buttons, etc).
class AppRadius {
  AppRadius._();
  static const card = 24.0; // rounded-3xl
  static const button = 16.0; // rounded-2xl
  static const pill = 999.0; // rounded-full
}