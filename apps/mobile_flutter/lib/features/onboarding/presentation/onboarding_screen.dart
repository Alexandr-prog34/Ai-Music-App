import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_router.dart';
import '../../../shared/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _t;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      context.go(Routes.generation);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF120F18),
      body: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          final brandOpacity = Curves.easeOut.transform(_t.value).clamp(0.0, 1.0);
          final brandScale = Tween<double>(
            begin: 0.965,
            end: 1,
          ).transform(_t.value);

          return Stack(
            children: [
              const _OnboardingBackdrop(),
              Positioned(
                left: 0,
                right: 0,
                top: size.height * 0.39,
                child: Opacity(
                  opacity: brandOpacity,
                  child: Transform.scale(
                    scale: brandScale,
                    child: const _BrandLockup(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF33243D),
                Color(0xFF17141E),
                Color(0xFF0F0C13),
              ],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        const _GlowBlob(
          alignment: Alignment(-1.05, -1.08),
          width: 220,
          height: 220,
          color: Color(0x4D7A2BFF),
        ),
        const _GlowBlob(
          alignment: Alignment(1.1, 0.18),
          width: 180,
          height: 180,
          color: Color(0x407A2BFF),
        ),
        const _GlowBlob(
          alignment: Alignment(-1.1, 0.78),
          width: 220,
          height: 220,
          color: Color(0x4D7128F5),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.025),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  static const _logoColor = Color(0xFF9B5CFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFBF8FFF),
                Color(0xFF8A49EA),
                Color(0xFF6530A8),
              ],
            ).createShader(bounds);
          },
          child: Text(
            'PULSE',
            textAlign: TextAlign.center,
            style: AppTypography.logo.copyWith(
              fontSize: 88,
              color: _logoColor,
              letterSpacing: 1.2,
              shadows: const [
                Shadow(
                  color: Color(0xAA8F4CFF),
                  blurRadius: 20,
                ),
                Shadow(
                  color: Color(0x663A136B),
                  blurRadius: 34,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI MUSIC GENERATOR',
          textAlign: TextAlign.center,
          style: AppTypography.subtitle.copyWith(
            fontSize: 14,
            color: const Color(0xFF8B5BE0),
            letterSpacing: 1.4,
            shadows: const [
              Shadow(
                color: Color(0x803F176D),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final double width;
  final double height;
  final Color color;

  const _GlowBlob({
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
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
