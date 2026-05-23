import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../library/domain/library_controller.dart';

class AiCoverScreen extends ConsumerStatefulWidget {
  const AiCoverScreen({super.key});

  @override
  ConsumerState<AiCoverScreen> createState() => _AiCoverScreenState();
}

class _AiCoverScreenState extends ConsumerState<AiCoverScreen> {
  Song? _selectedSong;

  void _openSongPicker() async {
    final songs = ref.read(songsProvider).valueOrNull ?? [];

    if (!mounted) return;

    final result = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SongPickerSheet(songs: songs),
    );

    if (result != null) {
      setState(() => _selectedSong = result);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _SelectSongCard(
                        selectedSong: _selectedSong,
                        onStartCreating: _openSongPicker,
                      ),
                      const SizedBox(height: 18),
                      const _SelectVoiceCard(),
                      const SizedBox(height: 18),
                      _GenerateButton(
                        enabled: _selectedSong != null,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Generate cover for "${_selectedSong!.title}"',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
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
}

// ─── Select song card ────────────────────────────────────────────────────────

class _SelectSongCard extends StatelessWidget {
  final Song? selectedSong;
  final VoidCallback onStartCreating;

  const _SelectSongCard({
    required this.selectedSong,
    required this.onStartCreating,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Song from Library',
            style: AppTypography.body.copyWith(color: AppColors.white85),
          ),
          const SizedBox(height: 12),
          if (selectedSong == null) ...[
            Center(
              child: Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.chipIdle,
                  border: Border.all(color: AppColors.white10, width: 0.5),
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Create your first song and\nmake an AI Cover right now',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.white75),
              ),
            ),
            const SizedBox(height: 14),
            Center(child: _SmallButton(label: 'Start Creating', onTap: onStartCreating)),
          ] else ...[
            _SelectedSongTile(title: selectedSong!.title, onTap: onStartCreating),
          ],
        ],
      ),
    );
  }
}

class _SelectedSongTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SelectedSongTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x44382060), border: Border.all(color: const Color(0x22FFFFFF), width: 0.5)),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.chipIdle, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16))),
        ]),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x44382060), border: Border.all(color: const Color(0x22FFFFFF), width: 0.5)),
        child: Text(label, style: AppTypography.button.copyWith(fontSize: 14)),
      ),
    );
  }
}

// ─── Select voice card ───────────────────────────────────────────────────────

class _SelectVoiceCard extends StatelessWidget {
  const _SelectVoiceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0x442A1060),
        border: Border.all(color: const Color(0x22FFFFFF), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Voice', style: AppTypography.body.copyWith(color: AppColors.white85)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.chipIdle, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.white10, width: 0.5)),
            child: Text('My Voices', style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.white85)),
          ),
          const SizedBox(height: 12),
          Container(
            width: 110, height: 120, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.chipIdle, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.white10, width: 0.5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.volume_up_rounded, color: AppColors.white85, size: 30),
              const SizedBox(height: 8),
              Text('Add your own\nvoices', textAlign: TextAlign.center, style: AppTypography.body.copyWith(fontSize: 11, color: AppColors.white85)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Generate button ─────────────────────────────────────────────────────────

class _GenerateButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _GenerateButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: enabled ? const Color(0x33FFFFFF) : const Color(0x18FFFFFF),
          border: Border.all(color: const Color(0x22FFFFFF), width: 0.5),
        ),
        child: Text(
          'Generate',
          style: AppTypography.button.copyWith(
            color: enabled ? Colors.white : AppColors.white35,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Song picker sheet — data comes from provider, not hardcoded ─────────────

class _SongPickerSheet extends StatelessWidget {
  final List<Song> songs;
  const _SongPickerSheet({required this.songs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, bottom: 18 + MediaQuery.of(context).padding.bottom, top: 80),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSheet,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.white10, width: 0.5),
          boxShadow: const [BoxShadow(offset: Offset(0, 18), blurRadius: 44, color: Color(0x66000000))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Song', style: AppTypography.title.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            if (songs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No songs yet. Create one first!',
                  style: AppTypography.body.copyWith(color: AppColors.white60),
                ),
              )
            else
              for (final song in songs) ...[
                _PickerSongTile(title: song.title, onTap: () => Navigator.of(context).pop(song)),
                const SizedBox(height: 10),
              ],
            _SmallButton(label: 'Cancel', onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _PickerSongTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _PickerSongTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x44382060), border: Border.all(color: const Color(0x22FFFFFF), width: 0.5)),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.chipIdle, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16))),
        ]),
      ),
    );
  }
}
