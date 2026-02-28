import 'package:flutter/material.dart';

import '../../../shared/assets/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../player/presentation/player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _showNewPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => const _NewPlaylistDialog(),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Важно: чтобы градиент был фоном всего
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _Background(),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: _TopBar(),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _SearchField(controller: _searchController),
                ),
                const SizedBox(height: 18),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 18,
                      right: 18,
                      bottom: 120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Playlists', style: AppTypography.title),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _PlaylistCard(
                                iconAsset: AppAssets.libraryFavorites,
                                label: 'My Favourites',
                                onTap: () {}
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _PlaylistCard(
                                iconAsset: AppAssets.libraryAddPlaylist,
                                label: 'New Playlist',
                                onTap: () => _showNewPlaylistDialog(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ArrowButton(onTap: () {}),
                          ],
                        ),

                        const SizedBox(height: 22),
                        const Text('My Songs', style: AppTypography.title),
                        const SizedBox(height: 12),

                        _SongTile(
                          title: 'Untitled #1',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PlayerScreen(title: 'Untitled #1'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _SongTile(
                          title: 'Untitled #2',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PlayerScreen(title: 'Untitled #2'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const AppBottomNav(active: AppTab.library),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Background ----------

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Container(
        // легкий glow как в макете
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.25),
            radius: 0.85,
            colors: [
              Color(0x40FFFFFF),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Top bar ----------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Text(
          'PULSE',
          style: TextStyle(
            fontFamily: AppTypography.logoFamily,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// ---------- Search ----------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.body.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search song, playlist...',
                hintStyle: AppTypography.body,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const AppIcon(AppAssets.librarySearch, size: 20),
        ],
      ),
    );
  }
}

/// ---------- Playlist cards ----------

class _PlaylistCard extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: _Glass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(iconAsset, size: 46),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ArrowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: AppIcon(AppAssets.libraryArrow, size: 28),
      ),
    );
  }
}

/// ---------- Songs ----------

class _SongTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SongTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 6),
              blurRadius: 18,
              color: Color(0x33000000),
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0x55FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}


/// ---------- Glass primitive ----------

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

class _NewPlaylistDialog extends StatefulWidget {
  const _NewPlaylistDialog();

  @override
  State<_NewPlaylistDialog> createState() => _NewPlaylistDialogState();
}

class _NewPlaylistDialogState extends State<_NewPlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0033).withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 16),
              blurRadius: 40,
              color: Color(0x66000000),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'New Playlist',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Playlist Name',
                style: AppTypography.body.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _Input(
              controller: _controller,
              hint: 'Type here...',
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Create',
                    filled: true,
                    onTap: () {
                      final name = _controller.text.trim();
                      // TODO: тут потом вызовешь controller/cubit: createPlaylist(name)
                      Navigator.of(context).pop(name.isEmpty ? null : name);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _Input({
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A004F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        style: AppTypography.body.copyWith(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTypography.body.copyWith(
            color: Colors.white.withOpacity(0.35),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? const Color(0xFFB79BFF).withOpacity(0.8)
        : const Color(0xFF2A004F).withOpacity(0.9);

    final fg = filled ? const Color(0xFF1A0033) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(filled ? 0.0 : 0.10),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            color: fg,
          ),
        ),
      ),
    );
  }
}