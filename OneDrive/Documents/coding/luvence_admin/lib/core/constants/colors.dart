import 'package:flutter/material.dart';

/// LUVENCE ID Design System Colors
/// Ported from web admin shared.jsx
class LuvColors {
  LuvColors._();

  // ── Primary Palette ──
  static const Color background = Color(0xFF0B0D14);
  static const Color surface = Color(0xFF0D0F1A);
  static const Color surfaceLight = Color(0xFF121526);
  static const Color card = Color(0xFF101320);

  // ── Accent Gold ──
  static const Color accent = Color(0xFFD4A574);
  static const Color accentLight = Color(0xFFE8C9A0);
  static const Color accentDark = Color(0xFFB07D4F);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // 60%
  static const Color textTertiary = Color(0x4DFFFFFF); // 30%
  static const Color textMuted = Color(0x33FFFFFF); // 20%

  // ── Borders ──
  static const Color border = Color(0x0FD4A574); // rgba(212,165,116,0.06)
  static const Color borderLight = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const Color borderAccent = Color(0x26D4A574); // rgba(212,165,116,0.15)

  // ── Glass ──
  static const Color glass = Color(0x04FFFFFF); // rgba(255,255,255,0.015)
  static const Color glassLight = Color(0x08FFFFFF); // rgba(255,255,255,0.03)
  static const Color glassMedium = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)

  // ── Status Colors ──
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF22D3EE);

  // ── Status Backgrounds ──
  static const Color successBg = Color(0x1A10B981);
  static const Color errorBg = Color(0x1AEF4444);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color infoBg = Color(0x1A3B82F6);
  static const Color cyanBg = Color(0x1A22D3EE);
  static const Color accentBg = Color(0x1AD4A574);

  // ── Gradients ──
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: [Color(0x9912152C), Color(0x4D0C0E1C)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0FD4A574), Color(0x088B5CF6)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.5, -0.5),
    end: Alignment(1.5, 0.5),
    colors: [
      Color(0xFF0D0F1A),
      Color(0xFF161929),
      Color(0xFF0D0F1A),
    ],
  );

  // ── Shadows ──
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];
}
