import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen background used by every screen.
///
/// Gradient + centered glow, exactly matching the Figma background layer.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.glowGradient),
        child: SizedBox.expand(),
      ),
    );
  }
}
