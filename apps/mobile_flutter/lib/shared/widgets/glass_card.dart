import 'package:flutter/material.dart';

/// Frosted-glass card — simulates blur-darkened glass without [BackdropFilter].
///
/// In Figma the cards used `backdrop-blur(20px)` + white overlay, which
/// darkened/blurred the purple gradient behind them. Since BackdropFilter
/// causes scroll artifacts on many Android devices (Xiaomi, Samsung),
/// we simulate the same look with a purple-tinted semi-transparent fill
/// + a subtle lighter top zone for the specular highlight.
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
        // Dark purple-tinted fill — looks like blurred purple gradient.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x55493080), // top-left: lighter purple-grey
            Color(0x44281050), // bottom-right: darker purple
          ],
        ),
        border: Border.all(color: const Color(0x30FFFFFF), width: 0.5),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 14,
            color: Color(0x20000000),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Specular highlight — brighter zone at top (simulates light on glass).
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
                    Color(0x14FFFFFF), // subtle bright edge
                    Color(0x00FFFFFF), // fade out
                  ],
                ),
              ),
            ),
          ),
          // Content.
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
