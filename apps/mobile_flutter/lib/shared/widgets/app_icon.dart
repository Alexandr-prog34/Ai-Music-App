import 'package:flutter/material.dart';

/// Renders a PNG asset icon at the given [size].
///
/// When [color] is provided the image is tinted via [BlendMode.srcIn].
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
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
    );
  }
}
