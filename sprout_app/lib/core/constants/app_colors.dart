import 'package:flutter/material.dart';

/// Design tokens — vivid, premium accents (avoid mutating at runtime).
abstract final class AppColors {
  static const Color seed = Color(0xFF0D9488);
  static const Color accentLime = Color(0xFFBEF264);
  static const Color accentCoral = Color(0xFFFF6B6B);

  /// Selected tab disc (Lush Growth).
  static const Color navSelected = Color(0xFFCC6F4E);
  static const Color accentSky = Color(0xFF38BDF8);
  static const Color accentViolet = Color(0xFFA78BFA);
  /// Page canvas (Lush Growth frames).
  static const Color surfaceDeep = Color(0xFF0F1413);

  /// Signed-in bottom bar fill — distinct from [surfaceDeep].
  static const Color surfaceBar = Color(0xFF1B2120);

  /// Muted panel fill (cards, tab headers, add-item rows, input backgrounds).
  static const Color surfaceMuted = Color(0xFF171D1C);
  static const Color environmentDev = Color(0xFFF59E0B);
  static const Color environmentProd = accentCoral;
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
