import 'package:flutter/material.dart';

/// Typography tokens extracted from Figma.
///
/// Figma fonts:
///   • Monoton          → logo / brand mark
///   • Jura             → mode-toggle labels
///   • Faustina         → body text, mood/genre pills, section titles
///   • Fredoka One      → bottom-nav labels, small caps
class AppTypography {
  AppTypography._();

  // ── Family constants (use in TextStyle.fontFamily) ────────────────
  static const fontFamily = 'Faustina';
  static const logoFamily = 'Monoton';
  static const tabFamily = 'Jura';
  static const navFamily = 'FredokaOne';

  // ── Pre-built styles ──────────────────────────────────────────────

  /// Large brand mark on the onboarding screen.
  static const logo = TextStyle(
    fontFamily: logoFamily,
    fontSize: 96,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    shadows: [
      Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0xFF632769)),
    ],
  );

  /// Top-left "PULSE" on inner screens (30 px).
  static const logoSmall = TextStyle(
    fontFamily: logoFamily,
    fontSize: 30,
    fontWeight: FontWeight.w400,
    color: Color(0x80FFFFFF),
    shadows: [
      Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0xFF632769)),
    ],
  );

  /// "AI MUSIC GENERATOR" on the splash.
  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0x80560EA3),
  );

  /// Section titles ("Select Mood", "My Playlists", etc.)
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 25,
    fontWeight: FontWeight.w400,
    color: Color(0xC9FFFFFF),
  );

  /// General body / hint text.
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xC9FFFFFF),
  );

  /// Prompt-card titles ("Describe your track").
  static const promptTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0xB3FFFFFF),
  );

  /// Mode-toggle text (Jura).
  static const tab = TextStyle(
    fontFamily: tabFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  /// CTA / primary button text.
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  /// Bottom-nav labels (Fredoka One, uppercase, letter-spacing 1.8).
  static const navLabel = TextStyle(
    fontFamily: navFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    letterSpacing: 1.8,
    shadows: [
      Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x40000000)),
    ],
  );

  /// Small labels / chips.
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );
}
