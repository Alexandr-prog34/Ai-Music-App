import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/playlist.dart';
import '../../../shared/assets/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../player/presentation/player_screen.dart';
import '../data/playlist_repository_impl.dart';
import '../domain/library_controller.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showNewPlaylistDialog() async {
    final result = await showDialog<_PlaylistEditResult>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _NewPlaylistDialog(
        onPickCover: _pickPlaylistCover,
      ),
    );
    if (result != null && result.name.isNotEmpty) {
      final repo = ref.read(playlistRepositoryProvider);
      final playlist = await repo.create(result.name);
      if (result.coverPath != null && result.coverPath!.isNotEmpty) {
        await repo.update(playlist.copyWith(coverPath: result.coverPath));
      }
      ref.invalidate(playlistsProvider);
    }
  }

  Future<String?> _pickPlaylistCover(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    return image?.path;
  }

  Future<void> _showPlaylistsSheet(List<Playlist> playlists) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaylistsSheet(
        playlists: playlists,
        onEdit: _editPlaylist,
        onDelete: _deletePlaylist,
      ),
    );
  }

  Future<void> _editPlaylist(Playlist playlist) async {
    final result = await showDialog<_PlaylistEditResult>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _NewPlaylistDialog(
        initialName: playlist.name,
        initialCoverPath: playlist.coverPath,
        title: 'Edit Playlist',
        submitLabel: 'Save',
        onPickCover: _pickPlaylistCover,
      ),
    );

    if (result == null || result.name.isEmpty || !mounted) return;

    await ref.read(playlistsProvider.notifier).updatePlaylist(
          playlist.copyWith(
            name: result.name,
            coverPath: result.coverPath,
          ),
        );
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    await ref.read(playlistsProvider.notifier).delete(playlist.id);
  }

  Future<void> _showFavoritesSheet(List<_FavoriteSongData> songs) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FavoritesSheet(songs: songs, onOpenSong: _openPlayer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);
    final playlistsAsync = ref.watch(playlistsProvider);
    final likedIdsAsync = ref.watch(likedSongIdsProvider);
    final playlists = playlistsAsync.valueOrNull ?? const <Playlist>[];
    final allSongs = songsAsync.valueOrNull ?? const [];
    final likedIds = likedIdsAsync.valueOrNull ?? const <String>{};
    final favoriteSongs = allSongs
        .where((song) => likedIds.contains(song.id))
        .map((song) => _FavoriteSongData(id: song.id, title: song.title))
        .toList();

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
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 138),
                  sliver: SliverList.list(
                    children: [
                      _SearchField(controller: _searchCtrl),
                      const SizedBox(height: 18),
                      Text('My Playlists', style: AppTypography.title),
                      const SizedBox(height: 12),
                      _PlaylistRow(
                        onFavorites: () => _showFavoritesSheet(favoriteSongs),
                        onMore: () => _showPlaylistsSheet(
                          playlists,
                        ),
                        onNewPlaylist: _showNewPlaylistDialog,
                      ),
                      const SizedBox(height: 22),
                      Text('My Songs', style: AppTypography.title),
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
    Navigator.of(context, rootNavigator: true).push(
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
              child: Text('Retry', style: AppTypography.label),
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x664F356F),
            Color(0x55332245),
            Color(0x663B195A),
          ],
        ),
        border: Border.all(color: const Color(0x30FFFFFF), width: 0.6),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 24,
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search song, playlist...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.white40, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const AppIcon(AppAssets.librarySearch, size: 24),
        ],
      ),
    );
  }
}

// ─── Playlist row ────────────────────────────────────────────────────────────

class _PlaylistRow extends StatelessWidget {
  final VoidCallback onFavorites;
  final VoidCallback onMore;
  final VoidCallback onNewPlaylist;
  const _PlaylistRow({
    required this.onFavorites,
    required this.onMore,
    required this.onNewPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _PlaylistCard(iconAsset: AppAssets.libraryFavorites, label: 'My Favourites', onTap: onFavorites)),
        const SizedBox(width: 14),
        Expanded(child: _PlaylistCard(iconAsset: AppAssets.libraryAddPlaylist, label: 'New Playlist', onTap: onNewPlaylist)),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onMore,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: AppIcon(AppAssets.libraryArrow, size: 24),
          ),
        ),
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
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: SizedBox(
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(iconAsset, size: 52),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
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
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x66523A71),
              Color(0x55322541),
              Color(0x664D285E),
            ],
          ),
          border: Border.all(color: const Color(0x2EFFFFFF), width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 10),
              blurRadius: 24,
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 10),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFAE8AD5),
                  Color(0xFF6B2F96),
                ],
              ),
              border: Border.all(color: const Color(0x36FFFFFF), width: 0.6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
        ]),
      ),
    );
  }
}

// ─── New playlist dialog ─────────────────────────────────────────────────────

class _NewPlaylistDialog extends StatefulWidget {
  final String initialName;
  final String? initialCoverPath;
  final String title;
  final String submitLabel;
  final Future<String?> Function(ImageSource source) onPickCover;

  const _NewPlaylistDialog({
    required this.onPickCover,
    this.initialName = '',
    this.initialCoverPath,
    this.title = 'New Playlist',
    this.submitLabel = 'Create',
  });

  @override
  State<_NewPlaylistDialog> createState() => _NewPlaylistDialogState();
}

class _NewPlaylistDialogState extends State<_NewPlaylistDialog> {
  late final TextEditingController _ctrl;
  String? _coverPath;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
    _coverPath = widget.initialCoverPath;
  }

  Future<void> _openEditPlaylistPictureDialog() async {
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => const _EditPlaylistPictureDialog(),
    );
    if (action == null) return;

    if (action == 'Remove Picture') {
      setState(() => _coverPath = '');
      return;
    }

    final source = action == 'Take Picture'
        ? ImageSource.camera
        : ImageSource.gallery;
    final path = await widget.onPickCover(source);
    if (path == null || !mounted) return;

    setState(() => _coverPath = path);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E2935),
              Color(0xFF17141C),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.white12, width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 18),
              blurRadius: 40,
              color: Color(0x66000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: AppTypography.title.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _PlaylistCoverBox(
                  size: 140,
                  coverPath: _coverPath,
                ),
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: GestureDetector(
                    onTap: _openEditPlaylistPictureDialog,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF9C78C8),
                            Color(0xFF7547A3),
                          ],
                        ),
                        border: Border.all(color: const Color(0x45FFFFFF), width: 0.6),
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Playlist Name',
                style: AppTypography.body.copyWith(
                  color: AppColors.white85,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x664F356F),
                    Color(0x66311F46),
                    Color(0xFF6D2F98),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x30FFFFFF), width: 0.6),
              ),
              child: TextField(
                controller: _ctrl,
                style: AppTypography.body.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type here...',
                  hintStyle: AppTypography.body.copyWith(color: AppColors.white35),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _DialogBtn(label: 'Cancel', filled: false, onTap: () => Navigator.of(context).pop())),
              const SizedBox(width: 12),
              Expanded(
                child: _DialogBtn(
                  label: widget.submitLabel,
                  filled: true,
                  onTap: () => Navigator.of(context).pop(
                    _PlaylistEditResult(
                      name: _ctrl.text.trim(),
                      coverPath: _coverPath,
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PlaylistEditResult {
  final String name;
  final String? coverPath;

  const _PlaylistEditResult({
    required this.name,
    required this.coverPath,
  });
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _DialogBtn({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF9C78C8),
                    Color(0xFF7547A3),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF24212B),
                    Color(0xFF1A1720),
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled ? const Color(0x36FFFFFF) : AppColors.white12,
            width: 0.6,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _PlaylistsSheet extends StatelessWidget {
  final List<Playlist> playlists;
  final ValueChanged<Playlist> onEdit;
  final ValueChanged<Playlist> onDelete;

  const _PlaylistsSheet({
    required this.playlists,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 106 + bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8A69B6),
              Color(0xFF5C377E),
              Color(0xFF4A226C),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x33FFFFFF), width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 18),
              blurRadius: 40,
              color: Color(0x55000000),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.68,
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                if (playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No playlists yet',
                      style: AppTypography.body.copyWith(color: AppColors.white60),
                    ),
                  )
                else
                  for (final playlist in playlists)
                    _PlaylistPreviewTile(
                      playlist: playlist,
                      onTap: () {
                        Navigator.of(context).pop();
                        onEdit(playlist);
                      },
                      onDelete: () {
                        Navigator.of(context).pop();
                        onDelete(playlist);
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesSheet extends StatelessWidget {
  final List<_FavoriteSongData> songs;
  final void Function(String id, String title) onOpenSong;

  const _FavoritesSheet({
    required this.songs,
    required this.onOpenSong,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 106 + bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF35283E),
              Color(0xFF1B171F),
              Color(0xFF110E14),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.white12, width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 18),
              blurRadius: 40,
              color: Color(0x55000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetSearchField(),
            const SizedBox(height: 18),
            Text('My Favourites', style: AppTypography.title.copyWith(fontSize: 18)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.46,
              ),
              child: songs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No liked songs yet',
                          style: AppTypography.body.copyWith(color: AppColors.white60),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int i = 0; i < songs.length; i++) ...[
                            _FavoriteSongTile(
                              title: songs[i].title,
                              onTap: () {
                                Navigator.of(context).pop();
                                onOpenSong(songs[i].id, songs[i].title);
                              },
                            ),
                            if (i != songs.length - 1) const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSearchField extends StatelessWidget {
  const _SheetSearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x664F356F),
            Color(0x55332245),
            Color(0x663B195A),
          ],
        ),
        border: Border.all(color: const Color(0x30FFFFFF), width: 0.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Search song, playlist...',
              style: AppTypography.body.copyWith(
                color: AppColors.white60,
                fontSize: 14,
              ),
            ),
          ),
          const AppIcon(AppAssets.librarySearch, size: 22),
        ],
      ),
    );
  }
}

class _FavoriteSongTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FavoriteSongTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x66523A71),
              Color(0x55322541),
              Color(0x664D285E),
            ],
          ),
          border: Border.all(color: const Color(0x2EFFFFFF), width: 0.6),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFAE8AD5),
                    Color(0xFF6B2F96),
                  ],
                ),
                border: Border.all(color: const Color(0x36FFFFFF), width: 0.6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _FavoriteSongData {
  final String id;
  final String title;

  const _FavoriteSongData({
    required this.id,
    required this.title,
  });
}

class _PlaylistPreviewTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistPreviewTile({
    required this.playlist,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            _PlaylistCoverBox(size: 88, coverPath: playlist.coverPath),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCoverBox extends StatelessWidget {
  final double size;
  final String? coverPath;

  const _PlaylistCoverBox({
    required this.size,
    this.coverPath,
  });

  @override
  Widget build(BuildContext context) {
    final path = coverPath?.trim();
    final hasCover = path != null && path.isNotEmpty;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size >= 120 ? 22 : 20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xB9B29BCB),
            Color(0x804F3D64),
          ],
        ),
        border: Border.all(color: const Color(0x30FFFFFF), width: 0.6),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 18,
            color: Color(0x22000000),
          ),
        ],
      ),
      child: hasCover
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          : null,
    );
  }
}

class _EditPlaylistPictureDialog extends StatelessWidget {
  const _EditPlaylistPictureDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E2935),
              Color(0xFF17141C),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.white12, width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 18),
              blurRadius: 40,
              color: Color(0x66000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Playlist Picture',
              style: AppTypography.body.copyWith(fontSize: 17, color: Colors.white),
            ),
            const SizedBox(height: 18),
            _PlaylistPictureOption(
              label: 'Take Picture',
              onTap: () => Navigator.of(context).pop('Take Picture'),
            ),
            const SizedBox(height: 12),
            _PlaylistPictureOption(
              label: 'Choose from Library',
              onTap: () => Navigator.of(context).pop('Choose from Library'),
            ),
            const SizedBox(height: 12),
            _PlaylistPictureOption(
              label: 'Remove Picture',
              onTap: () => Navigator.of(context).pop('Remove Picture'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistPictureOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PlaylistPictureOption({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A4450),
              Color(0xFF2B2531),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white12, width: 0.6),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
