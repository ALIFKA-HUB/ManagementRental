import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color lightBackground = Color(0xFFF2F2F6); // abu-abu sangat terang
  static const Color lightSurface = Color(0xFFFFFFFF); // putih murni
  
  // Dark Mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  
  // Brand
  static const Color primary = Color(0xFFA3E635); // lime: HANYA grafis & lencana kecil
  static const Color secondary = Color(0xFF1F2937);

  // Tombol utama (CTA) — hitam pekat dgn teks putih ala Neobank
  static const Color buttonBackground = Color(0xFF111827);
  static const Color buttonForeground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Text-on-color
  static const Color onPrimary = Color(0xFF1A2E05); // teks gelap di atas lime
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Status
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

  // Border / Divider — hairline tipis ala Flat & Airy
  static const Color divider = Color(0xFFE5E7EB); // legacy alias
  static const Color borderLight = Color(0xFFECEEF1);
  static const Color borderDark = Color(0xFF2A3650);

  // Surface muted — fill halus utk empty state, input, chip netral
  static const Color surfaceMutedLight = Color(0xFFF3F4F6);
  static const Color surfaceMutedDark = Color(0xFF243049);
}
