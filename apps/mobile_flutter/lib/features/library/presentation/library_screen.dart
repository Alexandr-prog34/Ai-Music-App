import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/assets/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../player/presentation/player_screen.dart';
import '../domain/library_controller.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showNewPlaylistDialog() async {
    final name = await showDialog<String>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => const _NewPlaylistDialog(),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(playlistsProvider.notifier).create(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
                  sliver: SliverList.list(
                    children: [
                      _SearchField(controller: _searchCtrl),
                      const SizedBox(height: 18),
                      const Text('My Playlists', style: AppTypography.title),
                      const SizedBox(height: 12),
                      _PlaylistRow(onNewPlaylist: _showNewPlaylistDialog),
                      const SizedBox(height: 22),
                      const Text('My Songs', style: AppTypography.title),
                      const SizedBox(height: 12),

                      // Proper AsyncValue handling.
                      songsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        error: (err, _) => _ErrorCard(
                          message: 'Failed to load songs',
                          onRetry: () => ref.invalidate(songsProvider),
                        ),
                        data: (songs) {
                          if (songs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'No songs yet.\nGo to CREATE to make your first track!',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.white60,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              for (int i = 0; i < songs.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                _SongTile(
                                  title: songs[i].title,
                                  onTap: () => _openPlayer(songs[i].id, songs[i].title),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayer(String id, String title) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlayerScreen(songId: id, title: title),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// ─── Error card ──────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.body.copyWith(color: AppColors.error)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.chipIdle,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text('Retry', style: AppTypography.label),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search ──────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.body.copyWith(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search song, playlist...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.white40),
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

// ─── Playlist row ────────────────────────────────────────────────────────────

class _PlaylistRow extends StatelessWidget {
  final VoidCallback onNewPlaylist;
  const _PlaylistRow({required this.onNewPlaylist});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PlaylistCard(iconAsset: AppAssets.libraryFavorites, label: 'My Favourites', onTap: () {})),
        const SizedBox(width: 14),
        Expanded(child: _PlaylistCard(iconAsset: AppAssets.libraryAddPlaylist, label: 'New Playlist', onTap: onNewPlaylist)),
        const SizedBox(width: 12),
        GestureDetector(onTap: () {}, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10), child: AppIcon(AppAssets.libraryArrow, size: 28))),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  const _PlaylistCard({required this.iconAsset, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AppIcon(iconAsset, size: 46),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center, style: AppTypography.label.copyWith(fontSize: 12)),
        ]),
      ),
    );
  }
}

// ─── Song tile ───────────────────────────────────────────────────────────────

class _SongTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SongTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0x44382060),
          border: Border.all(color: const Color(0x22FFFFFF), width: 0.5),
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16))),
          const SizedBox(width: 14),
        ]),
      ),
    );
  }
}

// ─── New playlist dialog ─────────────────────────────────────────────────────

class _NewPlaylistDialog extends StatefulWidget {
  const _NewPlaylistDialog();
  @override
  State<_NewPlaylistDialog> createState() => _NewPlaylistDialogState();
}

class _NewPlaylistDialogState extends State<_NewPlaylistDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSheet,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.white10, width: 0.5),
          boxShadow: const [BoxShadow(offset: Offset(0, 16), blurRadius: 40, color: Color(0x66000000))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New Playlist', style: AppTypography.title.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('Playlist Name', style: AppTypography.body.copyWith(color: AppColors.white85))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppColors.surfaceDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.white10, width: 0.5)),
              child: TextField(
                controller: _ctrl,
                style: AppTypography.body.copyWith(color: Colors.white),
                decoration: InputDecoration(border: InputBorder.none, hintText: 'Type here...', hintStyle: AppTypography.body.copyWith(color: AppColors.white35)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _DialogBtn(label: 'Cancel', filled: false, onTap: () => Navigator.of(context).pop())),
              const SizedBox(width: 12),
              Expanded(child: _DialogBtn(label: 'Create', filled: true, onTap: () => Navigator.of(context).pop(_ctrl.text.trim()))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _DialogBtn({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = filled ? const Color(0xCCB79BFF) : AppColors.surfaceSheet;
    final fg = filled ? AppColors.surface : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46, alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: filled ? Colors.transparent : AppColors.white10, width: 0.5)),
        child: Text(label, style: AppTypography.label.copyWith(color: fg, fontSize: 16)),
      ),
    );
  }
}
