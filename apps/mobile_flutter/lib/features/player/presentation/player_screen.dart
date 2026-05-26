import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/models/song.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/glass_card.dart';
import 'download_url_helper.dart';
import '../../library/data/playlist_repository_impl.dart';
import '../../library/data/song_repository_impl.dart';
import '../../library/domain/library_controller.dart';
import '../domain/player_controller.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String songId;
  final String title;

  const PlayerScreen({super.key, required this.songId, required this.title});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Future<void> _openSongOptions(PlayerState state, PlayerController ctrl) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _SongOptionsDialog(
        onAddToPlaylist: () async {
          Navigator.of(context).pop();
          await _openAddToPlaylist(state.song);
        },
        onRename: () async {
          Navigator.of(context).pop();
          await _openRenameDialog(state.song, ctrl);
        },
        onDelete: () async {
          Navigator.of(context).pop();
          await _openDeleteDialog(state.song);
        },
      ),
    );
  }

  Future<void> _openRenameDialog(Song song, PlayerController ctrl) async {
    final nextTitle = await showDialog<String>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _RenameSongDialog(initialTitle: song.title),
    );

    if (nextTitle == null || nextTitle.trim().isEmpty || nextTitle == song.title) {
      return;
    }

    await ctrl.renameSong(nextTitle.trim());
    ref.invalidate(songsProvider);
  }

  Future<void> _openDeleteDialog(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _DeleteSongDialog(songTitle: song.title),
    );

    if (confirmed != true) return;

    await ref.read(songRepositoryProvider).delete(song.id);
    ref.invalidate(songsProvider);
    ref.invalidate(likedSongIdsProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openAddToPlaylist(Song song) async {
    final playlists = await ref.read(playlistRepositoryProvider).getAll();

    if (!mounted) return;

    final result = await showDialog<_AddToPlaylistResult>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _AddToPlaylistDialog(
        playlists: playlists,
        song: song,
      ),
    );

    if (result == null) return;

    final repo = ref.read(playlistRepositoryProvider);

    String? playlistId = result.selectedPlaylistId;
    if ((playlistId == null || playlistId.isEmpty) &&
        result.newPlaylistName != null &&
        result.newPlaylistName!.trim().isNotEmpty) {
      final playlist = await repo.create(result.newPlaylistName!.trim());
      playlistId = playlist.id;
    }

    if (playlistId != null && playlistId.isNotEmpty) {
      await repo.addSong(playlistId, song.id);
      ref.invalidate(playlistsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song added to playlist'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEditPictureDialog() async {
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => const _EditPictureDialog(),
    );

    if (action == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action is not connected yet'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadTrack(PlayerController ctrl, Song song) async {
    try {
      final url = await ctrl.getDownloadUrl();
      final fileName = _buildDownloadFileName(song.title);

      await triggerTrackDownload(url, fileName: fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Track download started'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not download track: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _buildDownloadFileName(String title) {
    final sanitized = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final baseName = sanitized.isEmpty ? 'track' : sanitized;
    return '$baseName.mp3';
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(playerControllerProvider(widget.songId));
    final ctrl = ref.read(playerControllerProvider(widget.songId).notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: asyncState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load song',
                        style: AppTypography.body.copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text('Go back', style: AppTypography.label),
                      ),
                    ],
                  ),
                ),
                data: (state) => _PlayerBody(
                  state: state,
                  ctrl: ctrl,
                  onBack: () => Navigator.of(context).pop(),
                  onMore: () => _openSongOptions(state, ctrl),
                  onEditPicture: _openEditPictureDialog,
                  onDownload: () => _downloadTrack(ctrl, state.song),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  final PlayerState state;
  final PlayerController ctrl;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final VoidCallback onEditPicture;
  final VoidCallback onDownload;

  const _PlayerBody({
    required this.state,
    required this.ctrl,
    required this.onBack,
    required this.onMore,
    required this.onEditPicture,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        _TopBar(onBack: onBack, onMore: onMore),
        const SizedBox(height: 14),
        _CoverPlaceholder(onEdit: onEditPicture),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                state.song.title,
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayerActionButton(
                  icon: Icons.cloud_download_outlined,
                  onTap: onDownload,
                ),
                const SizedBox(width: 8),
                _LikeButton(liked: state.isLiked, onTap: ctrl.toggleLike),
              ],
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              state.song.mood ?? 'Song Mood',
              style: AppTypography.body.copyWith(
                fontSize: 10,
                color: AppColors.white60,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              state.song.genre ?? 'Song Genre',
              style: AppTypography.body.copyWith(
                fontSize: 10,
                color: AppColors.white60,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProgressSlider(value: state.progress, onChanged: ctrl.seek),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlIcon(icon: Icons.skip_previous_rounded, onTap: () {}),
            const SizedBox(width: 22),
            _PlayButton(isPlaying: state.isPlaying, onTap: ctrl.togglePlay),
            const SizedBox(width: 22),
            _ControlIcon(icon: Icons.skip_next_rounded, onTap: () {}),
          ],
        ),
        const SizedBox(height: 12),
        const _LyricsHeader(),
        const SizedBox(height: 8),
        Expanded(child: _LyricsCard(lyrics: state.song.lyrics)),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _TopBar({required this.onBack, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onMore,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final VoidCallback onEdit;

  const _CoverPlaceholder({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const GlassCard(
          radius: 22,
          child: SizedBox(height: 200, width: double.infinity),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF9B78C8),
                    Color(0xFF7446A2),
                  ],
                ),
                border: Border.all(color: const Color(0x40FFFFFF), width: 0.6),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final VoidCallback onTap;

  const _LikeButton({required this.liked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

class _PlayerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PlayerActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

class _ProgressSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ProgressSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        activeTrackColor: const Color(0xFF7D4BAD),
        inactiveTrackColor: AppColors.white18,
        thumbColor: const Color(0xFF6E339A),
        overlayColor: AppColors.white10,
      ),
      child: Slider(value: value.clamp(0, 1), onChanged: onChanged),
    );
  }
}

class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: AppColors.white85, size: 38),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7B4CAB),
              Color(0xFF51246E),
            ],
          ),
          border: Border.all(color: AppColors.white12, width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 14),
              blurRadius: 34,
              color: Color(0x44000000),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }
}

class _LyricsHeader extends StatelessWidget {
  const _LyricsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.white75),
        const SizedBox(height: 2),
        Text(
          'Lyrics',
          style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.white85),
        ),
      ],
    );
  }
}

class _LyricsCard extends StatelessWidget {
  final String? lyrics;

  const _LyricsCard({this.lyrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8C69B7),
            Color(0xFF6B3D93),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white12, width: 0.6),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 14),
            blurRadius: 40,
            color: Color(0x44000000),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          lyrics ?? 'Lyrics...',
          style: AppTypography.body.copyWith(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }
}

class _SongOptionsDialog extends StatelessWidget {
  final VoidCallback onAddToPlaylist;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _SongOptionsDialog({
    required this.onAddToPlaylist,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      alignment: const Alignment(0.45, -0.45),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A3B90),
              Color(0xFF44225E),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x36FFFFFF), width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 18),
              blurRadius: 40,
              color: Color(0x44000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MenuAction(
              icon: Icons.add_box_outlined,
              label: 'Add to Playlist',
              onTap: onAddToPlaylist,
            ),
            _MenuAction(
              icon: Icons.edit_outlined,
              label: 'Rename Song Title',
              onTap: onRename,
            ),
            _MenuAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Song',
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.body.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _DeleteSongDialog extends StatelessWidget {
  final String songTitle;

  const _DeleteSongDialog({required this.songTitle});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF5E5864),
                    Color(0xFF2F2936),
                  ],
                ),
                border: Border.all(color: AppColors.white12, width: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              songTitle,
              style: AppTypography.body.copyWith(fontSize: 9, color: AppColors.white40),
            ),
            const SizedBox(height: 14),
            Text(
              'Are you sure you want to\ndelete this song?',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(fontSize: 15, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DialogActionButton(
                    label: 'Cancel',
                    filled: false,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogActionButton(
                    label: 'Delete',
                    filled: true,
                    onTap: () => Navigator.of(context).pop(true),
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

class _RenameSongDialog extends StatefulWidget {
  final String initialTitle;

  const _RenameSongDialog({required this.initialTitle});

  @override
  State<_RenameSongDialog> createState() => _RenameSongDialogState();
}

class _RenameSongDialogState extends State<_RenameSongDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rename Song Title',
              style: AppTypography.body.copyWith(fontSize: 17, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
                borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DialogActionButton(
                    label: 'Cancel',
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogActionButton(
                    label: 'Save',
                    filled: true,
                    onTap: () => Navigator.of(context).pop(_ctrl.text.trim()),
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

class _AddToPlaylistDialog extends StatefulWidget {
  final List<Playlist> playlists;
  final Song song;

  const _AddToPlaylistDialog({
    required this.playlists,
    required this.song,
  });

  @override
  State<_AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<_AddToPlaylistDialog> {
  String? _selectedPlaylistId;
  bool _showNewPlaylistField = false;
  final TextEditingController _playlistCtrl = TextEditingController();

  @override
  void dispose() {
    _playlistCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to Playlist',
              style: AppTypography.body.copyWith(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showNewPlaylistField = !_showNewPlaylistField;
                  if (_showNewPlaylistField) _selectedPlaylistId = null;
                });
              },
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF8F69BA),
                      Color(0xFF7B4BA6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x40FFFFFF), width: 0.6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New Playlist',
                        style: AppTypography.body.copyWith(color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.add, color: Colors.white),
                  ],
                ),
              ),
            ),
            if (_showNewPlaylistField) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x30FFFFFF), width: 0.6),
                ),
                child: TextField(
                  controller: _playlistCtrl,
                  style: AppTypography.body.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type here...',
                    hintStyle: AppTypography.body.copyWith(color: AppColors.white35),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (widget.playlists.isNotEmpty)
              ...widget.playlists.map(
                (playlist) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlaylistChoiceTile(
                    playlist: playlist,
                    selected: _selectedPlaylistId == playlist.id,
                    onTap: () {
                      setState(() {
                        _selectedPlaylistId = playlist.id;
                        _showNewPlaylistField = false;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _DialogActionButton(
                label: 'Done',
                filled: true,
                onTap: () {
                  Navigator.of(context).pop(
                    _AddToPlaylistResult(
                      selectedPlaylistId: _selectedPlaylistId,
                      newPlaylistName:
                          _showNewPlaylistField ? _playlistCtrl.text.trim() : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistChoiceTile extends StatelessWidget {
  final Playlist playlist;
  final bool selected;
  final VoidCallback onTap;

  const _PlaylistChoiceTile({
    required this.playlist,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5E5864),
                  Color(0xFF2F2936),
                ],
              ),
              border: Border.all(color: AppColors.white12, width: 0.6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              playlist.name,
              style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16),
            ),
          ),
          Icon(
            selected ? Icons.check_circle_outline_rounded : Icons.circle_outlined,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _EditPictureDialog extends StatelessWidget {
  const _EditPictureDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Song Picture',
              style: AppTypography.body.copyWith(fontSize: 17, color: Colors.white),
            ),
            const SizedBox(height: 18),
            _WideOptionButton(
              label: 'Take Picture',
              onTap: () => Navigator.of(context).pop('Take Picture'),
            ),
            const SizedBox(height: 12),
            _WideOptionButton(
              label: 'Choose from Library',
              onTap: () => Navigator.of(context).pop('Choose from Library'),
            ),
            const SizedBox(height: 12),
            _WideOptionButton(
              label: 'Remove Picture',
              onTap: () => Navigator.of(context).pop('Remove Picture'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideOptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WideOptionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white12, width: 0.6),
        ),
        child: Text(label, style: AppTypography.body.copyWith(color: Colors.white)),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _DialogActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? const Color(0x36FFFFFF) : AppColors.white12,
            width: 0.6,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

BoxDecoration _dialogDecoration() {
  return BoxDecoration(
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
  );
}

class _AddToPlaylistResult {
  final String? selectedPlaylistId;
  final String? newPlaylistName;

  const _AddToPlaylistResult({
    required this.selectedPlaylistId,
    required this.newPlaylistName,
  });
}
