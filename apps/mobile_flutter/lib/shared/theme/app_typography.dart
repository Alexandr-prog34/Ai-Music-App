import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static const logoFamily = 'Monoton';

  static const logo = TextStyle(
    fontFamily: logoFamily,
    fontSize: 96,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    shadows: [
      Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0xFF632769)),
    ],
  );

  static const logoSmall = TextStyle(
    fontFamily: logoFamily,
    fontSize: 30,
    fontWeight: FontWeight.w400,
    color: Color(0x80FFFFFF),
    shadows: [
      Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0xFF632769)),
    ],
  );

  static TextStyle get subtitle => GoogleFonts.sen(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: const Color(0xCCFFFFFF),
      );

  static TextStyle get title => GoogleFonts.sen(
        fontSize: 25,
        fontWeight: FontWeight.w400,
        color: const Color(0xE0FFFFFF),
      );

  static TextStyle get body => GoogleFonts.sen(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: const Color(0xC9FFFFFF),
      );

  static TextStyle get promptTitle => GoogleFonts.sen(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: const Color(0xD9FFFFFF),
      );

  static TextStyle get tab => GoogleFonts.sen(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      );

  static TextStyle get button => GoogleFonts.sen(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      );

  static TextStyle get navLabel => GoogleFonts.sen(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.8,
        shadows: const [
          Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x40000000)),
        ],
      );

  static TextStyle get label => GoogleFonts.sen(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      );
}
