import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF8F3DFF);
  static const primaryDark = Color(0xFF5B1FA6);
  static const primaryDeep = Color(0xFF2A004F);

  static const accent = Color(0xFFE1A7FF);
  static const highlight = Color(0xFFF3CFFF);

  static const background = Color(0xFF0F001F);
  static const surface = Color(0xFF1A0033);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8A8D9);

  static const error = Color(0xFFFF4D6D);


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
}