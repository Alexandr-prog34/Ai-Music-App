import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/bottom_nav.dart';

class AiCoverScreen extends StatefulWidget {
  const AiCoverScreen({super.key});

  @override
  State<AiCoverScreen> createState() => _AiCoverScreenState();
}

class _AiCoverScreenState extends State<AiCoverScreen> {
  String? _selectedSongTitle;

  void _openSongPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SongPickerSheet(),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() => _selectedSongTitle = result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: _TopLogo(),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SelectSongCard(
                          selectedSongTitle: _selectedSongTitle,
                          onStartCreating: _openSongPicker,
                        ),
                        const SizedBox(height: 18),

                        const _SelectVoiceCard(),
                        const SizedBox(height: 18),

                        _GenerateButton(
                          enabled: _selectedSongTitle != null,
                          onTap: () {
                            // TODO: тут потом будет реальный запрос "сделай cover"
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _selectedSongTitle == null
                                      ? 'Select a song first'
                                      : 'Generate cover for "${_selectedSongTitle!}"',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const AppBottomNav(active: AppTab.aiCover),
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
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.25),
            radius: 0.85,
            colors: [Color(0x40FFFFFF), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

/// ---------- Top logo ----------

class _TopLogo extends StatelessWidget {
  const _TopLogo();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'PULSE',
        style: TextStyle(
          fontFamily: AppTypography.logoFamily,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// ---------- Select song card ----------

class _SelectSongCard extends StatelessWidget {
  final String? selectedSongTitle;
  final VoidCallback onStartCreating;

  const _SelectSongCard({
    required this.selectedSongTitle,
    required this.onStartCreating,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Song from Library',
            style: AppTypography.body.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          if (selectedSongTitle == null) ...[
            Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.14),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Create your first song and\nmake an AI Cover right now',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: _SmallButton(
                label: 'Start Creating',
                onTap: onStartCreating,
              ),
            ),
          ] else ...[
            _SelectedSongTile(
              title: selectedSongTitle!,
              onTap: onStartCreating, // можно тапом переоткрывать выбор
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedSongTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SelectedSongTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
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
          ],
        ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          label,
          style: AppTypography.button.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}

/// ---------- Select voice card ----------

class _SelectVoiceCard extends StatelessWidget {
  const _SelectVoiceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0033).withOpacity(0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 12),
            blurRadius: 30,
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Voice',
            style: AppTypography.body.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(label: 'My Voices', selected: true, onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),

          // карточка "Add your own voices"
          Container(
            width: 110,
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_up_rounded,
                    color: Colors.white.withOpacity(0.9), size: 30),
                const SizedBox(height: 8),
                Text(
                  'Add your own\nvoices',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 12,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
    );
  }
}

/// ---------- Generate button ----------

class _GenerateButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _GenerateButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? const Color(0x66000000) : const Color(0x33000000),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          'Generate',
          style: AppTypography.button.copyWith(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

/// ---------- Song picker sheet ----------

class _SongPickerSheet extends StatelessWidget {
  const _SongPickerSheet();

  @override
  Widget build(BuildContext context) {
    // Мок: позже ты подставишь реальные песни из Library controller
    final songs = const ['Untitled #1', 'Untitled #2'];

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: 18 + MediaQuery.of(context).padding.bottom,
        top: 80,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0033).withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 18),
              blurRadius: 44,
              color: Color(0x66000000),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Song',
              style: AppTypography.title.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),

            for (final s in songs) ...[
              _PickerSongTile(
                title: s,
                onTap: () => Navigator.of(context).pop(s),
              ),
              const SizedBox(height: 10),
            ],

            _SmallButton(
              label: 'Cancel',
              onTap: () => Navigator.of(context).pop(),
            ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
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
          ],
        ),
      ),
    );
  }
}

/// ---------- Glass primitive for top card ----------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _GlassCard({
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