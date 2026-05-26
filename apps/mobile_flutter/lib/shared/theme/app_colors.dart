import 'package:flutter/material.dart';

/// Design tokens extracted from Figma (PULSE — AI Music Generator).
///
/// Names describe the *role*, not the hue, so call-sites stay readable.
class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────────
  static const primary = Color(0xFF8A62C8);
  static const primaryDark = Color(0xFF40205F);
  static const primaryDeep = Color(0xFF25132F);
  static const surface = Color(0xFF15121B);

  static const accent = Color(0xFFB185E8);
  static const highlight = Color(0xFFD2B1FF);
  static const error = Color(0xFFFF4D6D);

  // ── Text ───────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFC7BDD4);

  // ── Chips / pills (Figma: rgba(73,26,177,0.25)) ──────────────────
  static const chipIdle = Color(0x5231283F);
  static const chipDark = Color(0xD61B1721);
  static const chipSelected = Color(0x8A71439F);

  // ── Mode toggle ────────────────────────────────────────────────────
  static const toggleBackground = Color(0xCC211C28);
  static const toggleActive = Color(0xFF7F57B3);

  // ── Glass / overlays ──────────────────────────────────────────────
  static const glassWhiteHi = Color(0x2EFFFFFF);
  static const glassWhiteLo = Color(0x14FFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);

  // ── Bottom nav bar (Figma: backdrop-blur + rgba(255,255,255,0.2)) ─
  static const navBarFill = Color(0xCC241C31);

  // ── Backgrounds ───────────────────────────────────────────────────
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF18131F),
      Color(0xFF120F18),
      Color(0xFF0B090E),
    ],
    stops: [0.18, 0.56, 1],
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
  static const surfaceSheet = Color(0xEB17131B);

  /// Surface at 85 % — lyrics card, etc.
  static const surfaceDim = Color(0xD91C1822);

  /// Primary at 45 % — play button fill.
  static const primaryMuted = Color(0x737F57B3);

  /// Subtle centre-glow overlay used on most screens.
  static const glowGradient = RadialGradient(
    center: Alignment(-0.15, -0.2),
    radius: 1.0,
    colors: [Color(0x146E31C8), Colors.transparent],
  );
}
