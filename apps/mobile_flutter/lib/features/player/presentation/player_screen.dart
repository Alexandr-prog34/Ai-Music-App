import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class PlayerScreen extends StatefulWidget {
  final String title;

  const PlayerScreen({
    super.key,
    required this.title,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _progress = 0.62; // стаб для ползунка
  bool _isPlaying = false;
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _Background(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  _TopBar(
                    onBack: () => Navigator.of(context).pop(),
                    onMore: () {},
                  ),
                  const SizedBox(height: 18),

                  // Cover placeholder (без фотки — как в макете просто квадрат)
                  const _CoverPlaceholder(),
                  const SizedBox(height: 18),

                  // Title + like
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AppTypography.title.copyWith(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _LikeButton(
                        liked: _isLiked,
                        onTap: () => setState(() => _isLiked = !_isLiked),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Mood / Genre (как подписи под названием)
                  Row(
                    children: [
                      Text(
                        'Song Mood',
                        style: AppTypography.body.copyWith(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Song Genre',
                        style: AppTypography.body.copyWith(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Progress
                  _ProgressSlider(
                    value: _progress,
                    onChanged: (v) => setState(() => _progress = v),
                  ),

                  const SizedBox(height: 18),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlIcon(
                        icon: Icons.skip_previous_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 18),
                      _PlayButton(
                        isPlaying: _isPlaying,
                        onTap: () => setState(() => _isPlaying = !_isPlaying),
                      ),
                      const SizedBox(width: 18),
                      _ControlIcon(
                        icon: Icons.skip_next_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Lyrics header (стрелочка вверх + текст)
                  const _LyricsHeader(),

                  const SizedBox(height: 10),

                  // Lyrics card
                  const Expanded(
                    child: _LyricsCard(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
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
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.15),
            radius: 0.9,
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
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _TopBar({required this.onBack, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onMore,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// ---------- Cover placeholder ----------

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.06),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
        ),

        // маленькая кнопка "карандаш" внизу справа
        Positioned(
          right: 14,
          bottom: 14,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

/// ---------- Like ----------

class _LikeButton extends StatelessWidget {
  final bool liked;
  final VoidCallback onTap;

  const _LikeButton({required this.liked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

/// ---------- Progress slider ----------

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
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: Colors.white.withOpacity(0.55),
        inactiveTrackColor: Colors.white.withOpacity(0.18),
        thumbColor: Colors.white.withOpacity(0.65),
        overlayColor: Colors.white.withOpacity(0.10),
      ),
      child: Slider(
        value: value.clamp(0, 1),
        onChanged: onChanged,
      ),
    );
  }
}

/// ---------- Controls ----------

class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 44),
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
    return InkWell(
      borderRadius: BorderRadius.circular(44),
      onTap: onTap,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 14),
              blurRadius: 34,
              color: Color(0x44000000),
            )
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}

/// ---------- Lyrics ----------

class _LyricsHeader extends StatelessWidget {
  const _LyricsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.keyboard_arrow_up_rounded,
            color: Colors.white.withOpacity(0.75)),
        const SizedBox(height: 2),
        Text(
          'Lyrics',
          style: AppTypography.body.copyWith(
            fontSize: 14,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}

class _LyricsCard extends StatelessWidget {
  const _LyricsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0033).withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 14),
            blurRadius: 40,
            color: Color(0x44000000),
          )
        ],
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          'Lyrics...',
          style: AppTypography.body.copyWith(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}