// lib/presentation/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Surface Colors
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Utility Colors
  static Color primaryAlpha10 = primary.withValues(alpha: 0.1);
  static Color primaryAlpha20 = primary.withValues(alpha: 0.2);
  static Color primaryAlpha30 = primary.withValues(alpha: 0.3);
  static Color whiteAlpha70 = Colors.white.withValues(alpha: 0.7);
  static Color whiteAlpha15 = Colors.white.withValues(alpha: 0.15);
  static Color whiteAlpha30 = Colors.white.withValues(alpha: 0.3);

  // Gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceLight, surface],
  );

  // Box Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: textMuted.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: textMuted.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
