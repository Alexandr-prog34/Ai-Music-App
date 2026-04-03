import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_router.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_background.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          Center(
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, __) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AnimatedWord(
                      text: 'PULSE',
                      progress: _t.value,
                      style: AppTypography.logo,
                      perCharDelay: 0.10,
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: (_t.value - 0.55).clamp(0.0, 1.0),
                      child: const Text(
                        'AI MUSIC GENERATOR',
                        style: AppTypography.subtitle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Letters appear one by one with a gentle slide-up + fade-in.
class _AnimatedWord extends StatelessWidget {
  final String text;
  final double progress;
  final TextStyle style;
  final double perCharDelay;

  const _AnimatedWord({
    required this.text,
    required this.progress,
    required this.style,
    this.perCharDelay = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < chars.length; i++)
          _AnimatedChar(
            char: chars[i],
            style: style,
            t: ((progress - i * perCharDelay) /
                    (1 - (chars.length - 1) * perCharDelay))
                .clamp(0.0, 1.0),
          ),
      ],
    );
  }
}

class _AnimatedChar extends StatelessWidget {
  final String char;
  final double t;
  final TextStyle style;

  const _AnimatedChar({
    required this.char,
    required this.t,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final dy = (1 - t) * 12;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Text(char, style: style),
      ),
    );
  }
}
