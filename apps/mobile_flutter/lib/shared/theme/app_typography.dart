import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const fontFamily = 'NicoMoji';
  static const logoFamily = 'Monoton';

  static const logo = TextStyle(
    fontFamily: logoFamily,
    fontSize: 96,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(0, 4),
        blurRadius: 4,
        color: Color(0xFF632769),
      ),
    ],
  );

  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0x80560EA3),
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0x80560EA3),
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );
}