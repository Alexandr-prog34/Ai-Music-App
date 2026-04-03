import 'package:flutter/material.dart';

/// Design tokens extracted from Figma (PULSE — AI Music Generator).
///
/// Names describe the *role*, not the hue, so call-sites stay readable.
class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────────
  static const primary = Color(0xFF734ACD);
  static const primaryDark = Color(0xFF210957);
  static const primaryDeep = Color(0xFF2A004F);
  static const surface = Color(0xFF1A0033);

  static const accent = Color(0xFFE1A7FF);
  static const highlight = Color(0xFFF3CFFF);
  static const error = Color(0xFFFF4D6D);

  // ── Text ───────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8A8D9);

  // ── Chips / pills (Figma: rgba(73,26,177,0.25)) ──────────────────
  static const chipIdle = Color(0x40491AB1);
  static const chipDark = Color(0xB3210957);
  static const chipSelected = Color(0x66734ACD);

  // ── Mode toggle ────────────────────────────────────────────────────
  static const toggleBackground = Color(0xFF210957);
  static const toggleActive = Color(0xFF734ACD);

  // ── Glass / overlays ──────────────────────────────────────────────
  static const glassWhiteHi = Color(0x2EFFFFFF);
  static const glassWhiteLo = Color(0x14FFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);

  // ── Bottom nav bar (Figma: backdrop-blur + rgba(255,255,255,0.2)) ─
  static const navBarFill = Color(0x33FFFFFF);

  // ── Backgrounds ───────────────────────────────────────────────────
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2A004F),
      Color(0xFF5B1FA6),
      Color(0xFF8F3DFF),
      Color(0xFFE1A7FF),
    ],
  );

  // ── Commonly-used white opacities (avoids withOpacity at call-site) ──
  static const white85 = Color(0xD9FFFFFF); // 85 %
  static const white75 = Color(0xBFFFFFFF); // 75 %
  static const white65 = Color(0xA6FFFFFF); // 65 %
  static const white60 = Color(0x99FFFFFF); // 60 %
  static const white55 = Color(0x8CFFFFFF); // 55 %
  static const white45 = Color(0x73FFFFFF); // 45 %
  static const white40 = Color(0x66FFFFFF); // 40 %
  static const white35 = Color(0x59FFFFFF); // 35 %
  static const white18 = Color(0x2EFFFFFF); // 18 %
  static const white15 = Color(0x26FFFFFF); // 15 %
  static const white12 = Color(0x1FFFFFFF); // 12 %
  static const white10 = Color(0x1AFFFFFF); // 10 %

  /// Surface at 92 % opacity — used for bottom sheets and dialogs.
  static const surfaceSheet = Color(0xEB1A0033);

  /// Surface at 85 % — lyrics card, etc.
  static const surfaceDim = Color(0xD91A0033);

  /// Primary at 45 % — play button fill.
  static const primaryMuted = Color(0x73734ACD);

  /// Subtle centre-glow overlay used on most screens.
  static const glowGradient = RadialGradient(
    center: Alignment(0, 0.25),
    radius: 0.85,
    colors: [Color(0x40FFFFFF), Colors.transparent],
  );
}
