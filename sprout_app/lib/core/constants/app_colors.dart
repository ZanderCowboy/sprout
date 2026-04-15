import 'package:flutter/material.dart';

/// Design tokens — vivid, premium accents (avoid mutating at runtime).
abstract final class AppColors {
  static const Color seed = Color(0xFF0D9488);
  static const Color accentLime = Color(0xFFBEF264);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentSky = Color(0xFF38BDF8);
  static const Color accentViolet = Color(0xFFA78BFA);
  static const Color surfaceDeep = Color(0xFF0F172A);
  static const List<Color> cardPalette = [
    Color(0xFF14B8A6),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
  ];

  static Color cardColorAt(int index) =>
      cardPalette[index % cardPalette.length];
}
