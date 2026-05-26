import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen background used by every screen.
///
/// Gradient + centered glow, exactly matching the Figma background layer.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),
        _BackgroundGlow(
          alignment: Alignment(-1.1, -0.92),
          width: 220,
          height: 220,
          color: Color(0x306B2AD8),
        ),
        _BackgroundGlow(
          alignment: Alignment(0.92, 0.12),
          width: 170,
          height: 170,
          color: Color(0x245D21BE),
        ),
        _BackgroundGlow(
          alignment: Alignment(-1.05, 0.78),
          width: 200,
          height: 200,
          color: Color(0x28672BCF),
        ),
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.glowGradient),
          child: SizedBox.expand(),
        ),
      ],
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final Alignment alignment;
  final double width;
  final double height;
  final Color color;

  const _BackgroundGlow({
    required this.alignment,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
