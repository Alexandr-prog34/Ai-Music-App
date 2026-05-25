import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x8A4A4253),
            Color(0x66312739),
            Color(0x8018151D),
          ],
        ),
        border: Border.all(color: AppColors.white12, width: 0.6),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 26,
            color: Color(0x38000000),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x18FFFFFF),
                    Color(0x08C5B6D8),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
