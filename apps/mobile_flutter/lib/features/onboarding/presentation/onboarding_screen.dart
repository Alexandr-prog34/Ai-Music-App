import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/routing/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  Timer? _timer;

  final String _title = 'PULSE';
  final String _subtitle = 'AI MUSIC GENERATOR';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    _t = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    // через 5 сек → на generation
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      context.go(Routes.generation);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _Background(),

          Center(
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AnimatedWord(
                      text: _title,
                      progress: _t.value,
                      style: AppTypography.logo,
                      // чуть “печатается” по буквам
                      perCharDelay: 0.10,
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: (_t.value - 0.55).clamp(0, 1),
                      child: Text(
                        _subtitle,
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

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.2),
            radius: 0.85,
            colors: [Color(0x55FFFFFF), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

/// Анимация “буквы появляются по очереди”
class _AnimatedWord extends StatelessWidget {
  final String text;
  final double progress; // 0..1
  final TextStyle style;
  final double perCharDelay; // сколько доля на букву (например 0.1)

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
            // каждая следующая буква появляется чуть позже
            t: ((progress - i * perCharDelay) / (1 - (chars.length - 1) * perCharDelay))
                .clamp(0.0, 1.0),
          ),
      ],
    );
  }
}

class _AnimatedChar extends StatelessWidget {
  final String char;
  final double t; // 0..1
  final TextStyle style;

  const _AnimatedChar({
    required this.char,
    required this.t,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    // лёгкий подъём + fade-in
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