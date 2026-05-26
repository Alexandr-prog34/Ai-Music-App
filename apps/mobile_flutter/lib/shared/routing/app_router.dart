import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/generation/presentation/generation_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/bottom_nav.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.onboarding,
    routes: [
      // Onboarding — no tab bar.
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (_, __) => _fadePage(
          const OnboardingScreen(),
          name: 'onboarding',
        ),
      ),

      // Main shell — tab bar persists, only inner content swaps.
      ShellRoute(
        builder: (context, state, child) {
          return _TabShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: Routes.generation,
            pageBuilder: (_, __) => _fadePage(
              const GenerationScreen(),
              name: 'generation',
            ),
          ),
          GoRoute(
            path: Routes.library,
            pageBuilder: (_, __) => _fadePage(
              const LibraryScreen(),
              name: 'library',
            ),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (_, __) => _fadePage(
              const SettingsScreen(),
              name: 'settings',
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route error: ${state.error}')),
    ),
  );
});

/// Shell that keeps [AppBottomNav] alive across tab switches.
///
/// Because the nav bar widget stays mounted, its [AnimationController]s
/// survive route changes and can animate smoothly from old → new state.
class _TabShell extends StatelessWidget {
  final String location;
  final Widget child;

  const _TabShell({required this.location, required this.child});

  AppTab get _activeTab {
    if (location.startsWith(Routes.library)) return AppTab.library;
    return AppTab.create;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Screen content fills entire area.
          child,
          // Tab bar floats on top — never rebuilds on route change.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(active: _activeTab),
          ),
        ],
      ),
    );
  }
}

CustomTransitionPage<void> _fadePage(Widget child, {required String name}) {
  return CustomTransitionPage<void>(
    name: name,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

abstract class Routes {
  static const onboarding = '/onboarding';
  static const generation = '/generation';
  static const library = '/library';
  static const settings = '/settings';
}
