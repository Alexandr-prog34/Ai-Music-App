import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';

enum AppTab { aiCover, create, library }

class AppBottomNav extends StatelessWidget {
  final AppTab active;
  final VoidCallback? onAiCover;
  final VoidCallback? onCreate;
  final VoidCallback? onLibrary;

  const AppBottomNav({
    super.key,
    required this.active,
    this.onAiCover,
    this.onCreate,
    this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: _Glass(
        radius: 26,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomItem(
              label: 'AI COVER',
              asset: AppAssets.navAiCover,
              active: active == AppTab.aiCover,
              onTap: () {
                if (active != AppTab.aiCover) context.go(Routes.aiCover);
              },
            ),
            _BottomItem(
              label: 'CREATE',
              asset: AppAssets.navCreate,
              active: active == AppTab.create,
              onTap: () {
                if (active != AppTab.create) context.go(Routes.generation);
              },
            ),
            _BottomItem(
              label: 'LIBRARY',
              asset: AppAssets.navLibrary,
              active: active == AppTab.library,
              onTap: () {
                if (active != AppTab.library) context.go(Routes.library);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final String label;
  final String asset;
  final bool active;
  final VoidCallback? onTap;

  const _BottomItem({
    required this.label,
    required this.asset,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // вот этот “фиолетовый квадрат”
          color: active ? const Color(0x66000000) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(asset, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Такой же glass как в Library
class _Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _Glass({
    required this.child,
    required this.radius,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 28,
            color: Color(0x33000000),
          ),
        ],
      ),
      child: child,
    );
  }
}