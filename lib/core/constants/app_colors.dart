import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand - Neon Green
  static const Color primary = Color(0xFF39FF14);
  static const Color primaryDark = Color(0xFF00E676);
  static const Color accent = Color(0xFF64FFDA);

  // Backgrounds
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardElevated = Color(0xFF222222);

  // Borders
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF3A3A3A);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF424242);

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF40C4FF);

  // Category Colors
  static const Color investment = Color(0xFF39FF14);
  static const Color loan = Color(0xFFFF6B6B);
  static const Color savings = Color(0xFF40C4FF);
  static const Color tax = Color(0xFFFFC107);
  static const Color business = Color(0xFFCE93D8);
  static const Color utility = Color(0xFF64FFDA);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF39FF14),
    Color(0xFF64FFDA),
    Color(0xFF40C4FF),
    Color(0xFFCE93D8),
    Color(0xFFFF6B6B),
    Color(0xFFFFC107),
  ];

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF39FF14), Color(0xFF00E676)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF222222), Color(0xFF1A1A1A)],
  );

  // Glow effects
  static List<BoxShadow> neonGlow(Color color, {double blur = 12, double spread = 0}) => [
    BoxShadow(color: color.withOpacity(0.4), blurRadius: blur, spreadRadius: spread),
    BoxShadow(color: color.withOpacity(0.2), blurRadius: blur * 2, spreadRadius: spread),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
  ];
}
