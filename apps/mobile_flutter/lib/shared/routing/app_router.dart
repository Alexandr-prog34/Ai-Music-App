import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/generation/presentation/generation_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/ai_cover/presentation/ai_cover_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.generation,
        builder: (context, state) => const GenerationScreen(),
      ),
      GoRoute(
        path: Routes.library,
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: Routes.aiCover,
        builder: (context, state) => const AiCoverScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
});

abstract class Routes {
  static const generation = '/generation';
  static const library = '/library';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
  static const aiCover = '/ai-cover';
}