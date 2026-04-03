import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/player_controller.dart';

class PlayerScreen extends ConsumerWidget {
  final String songId;
  final String title;

  const PlayerScreen({super.key, required this.songId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(playerControllerProvider(songId));
    final ctrl = ref.read(playerControllerProvider(songId).notifier);

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
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Could not load song', style: AppTypography.body.copyWith(color: AppColors.error)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text('Go back', style: AppTypography.label),
                      ),
                    ],
                  ),
                ),
                data: (state) => _PlayerBody(state: state, ctrl: ctrl, onBack: () => Navigator.of(context).pop()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted body to keep [build] lean.
class _PlayerBody extends StatelessWidget {
  final PlayerState state;
  final PlayerController ctrl;
  final VoidCallback onBack;

  const _PlayerBody({required this.state, required this.ctrl, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        _TopBar(onBack: onBack, onMore: () {}),
        const SizedBox(height: 18),
        const _CoverPlaceholder(),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(state.song.title, style: AppTypography.title.copyWith(fontSize: 28))),
          _LikeButton(liked: state.isLiked, onTap: ctrl.toggleLike),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Text(state.song.mood ?? 'No mood', style: AppTypography.body.copyWith(fontSize: 11, color: AppColors.white60)),
          const SizedBox(width: 16),
          Text(state.song.genre ?? 'No genre', style: AppTypography.body.copyWith(fontSize: 11, color: AppColors.white60)),
        ]),
        const SizedBox(height: 14),
        _ProgressSlider(value: state.progress, onChanged: ctrl.seek),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ControlIcon(icon: Icons.skip_previous_rounded, onTap: () {}),
          const SizedBox(width: 18),
          _PlayButton(isPlaying: state.isPlaying, onTap: ctrl.togglePlay),
          const SizedBox(width: 18),
          _ControlIcon(icon: Icons.skip_next_rounded, onTap: () {}),
        ]),
        const SizedBox(height: 14),
        const _LyricsHeader(),
        const SizedBox(height: 10),
        Expanded(child: _LyricsCard(lyrics: state.song.lyrics)),
        const SizedBox(height: 16),
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
    return Row(children: [
      GestureDetector(onTap: onBack, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white))),
      const Spacer(),
      GestureDetector(onTap: onMore, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.more_vert_rounded, color: Colors.white))),
    ]);
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const GlassCard(child: SizedBox(height: 250, width: double.infinity)),
      Positioned(
        right: 14, bottom: 14,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.white15, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.white12, width: 0.5)),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
        ),
      ),
    ]);
  }
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final VoidCallback onTap;
  const _LikeButton({required this.liked, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Padding(padding: const EdgeInsets.all(6), child: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.white, size: 30)));
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
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        activeTrackColor: AppColors.white55,
        inactiveTrackColor: AppColors.white18,
        thumbColor: AppColors.white65,
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
    return GestureDetector(onTap: onTap, child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: AppColors.white85, size: 44)));
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
        width: 86, height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryMuted,
          border: Border.all(color: AppColors.white12, width: 0.5),
          boxShadow: const [BoxShadow(offset: Offset(0, 14), blurRadius: 34, color: Color(0x44000000))],
        ),
        child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}

class _LyricsHeader extends StatelessWidget {
  const _LyricsHeader();
  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.white75),
      SizedBox(height: 2),
      Text('Lyrics', style: TextStyle(fontFamily: 'Faustina', fontSize: 14, color: AppColors.white85)),
    ]);
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
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.white10, width: 0.5),
        boxShadow: const [BoxShadow(offset: Offset(0, 14), blurRadius: 40, color: Color(0x44000000))],
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(lyrics ?? 'No lyrics available', style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.white75)),
      ),
    );
  }
}
