import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const AppIcon(
      this.asset, {
        super.key,
        this.size = 24,
        this.color,
      });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // если иконки монохромные (белые/фиолетовые линии) — их можно тинтить
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
    );
  }
}