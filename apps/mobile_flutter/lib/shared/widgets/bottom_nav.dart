import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../assets/app_assets.dart';
import '../routing/app_router.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

enum AppTab { aiCover, create, library }

/// Floating dark tab bar — solid fill, no BackdropFilter.
///
/// Active tab: icon + label in a highlighted pill (smooth expand).
/// Inactive tabs: icon only, dimmed.
class AppBottomNav extends StatelessWidget {
  final AppTab active;

  const AppBottomNav({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(40, 0, 40, 16 + bottomPad),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xCC2A1050),
          border: Border.all(color: const Color(0x22FFFFFF), width: 0.5),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 16,
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              asset: AppAssets.navAiCover,
              label: 'AI COVER',
              active: active == AppTab.aiCover,
              onTap: () {
                if (active != AppTab.aiCover) context.go(Routes.aiCover);
              },
            ),
            _NavItem(
              asset: AppAssets.navCreate,
              label: 'CREATE',
              active: active == AppTab.create,
              onTap: () {
                if (active != AppTab.create) context.go(Routes.generation);
              },
            ),
            _NavItem(
              asset: AppAssets.navLibrary,
              label: 'LIBRARY',
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

class _NavItem extends StatefulWidget {
  final String asset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.asset,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.active ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant _NavItem old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _anim.forward() : _anim.reverse();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final raw = _anim.value;
          final t = 1 - (1 - raw) * (1 - raw) * (1 - raw);

          final labelWidth = _measureText(
            widget.label,
            AppTypography.navLabel.copyWith(fontSize: 10, letterSpacing: 0.8),
          );

          return Container(
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: 10 + 2 * t),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Color.fromRGBO(255, 255, 255, 0.18 * t),
              border: t > 0.1
                  ? Border.all(
                      color: Color.fromRGBO(255, 255, 255, 0.12 * t),
                      width: 0.5,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  widget.asset,
                  size: 20,
                  color: Color.lerp(
                    const Color(0x77FFFFFF),
                    const Color(0xFFFFFFFF),
                    t,
                  ),
                ),
                SizedBox(width: 6.0 * t),
                ClipRect(
                  child: SizedBox(
                    width: labelWidth * t,
                    child: Opacity(
                      opacity: t,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: AppTypography.navLabel.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _measureText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }
}
