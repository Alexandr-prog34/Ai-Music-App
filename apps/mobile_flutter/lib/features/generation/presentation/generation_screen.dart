import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import 'generation_controller.dart';
import 'package:mobile_flutter/shared/assets/app_assets.dart';
import 'package:mobile_flutter/shared/widgets/app_icon.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/bottom_nav.dart';

class GenerationScreen extends ConsumerWidget {
  const GenerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(generationFormProvider);
    final ctrl = ref.read(generationFormProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top logo placeholder (позже сделаем как в Figma)
                      const _TopLogo(),

                      const SizedBox(height: 14),

                      _ModeToggle(
                        mode: st.mode,
                        onChanged: ctrl.setMode,
                      ),

                      const SizedBox(height: 14),

                      _PromptCard(
                        title: st.mode == GenerationMode.description
                            ? 'Describe your track'
                            : 'Write your lyrics',
                        hint: 'Type here...',
                        value: st.promptText,
                        onChanged: ctrl.setPromptText,
                      ),

                      const SizedBox(height: 18),

                      _MoodSection(
                        selected: st.mood,
                        onSelect: ctrl.selectMood,
                        onMore: () => _showMoodMoreSheet(context, ref),
                      ),

                      const SizedBox(height: 14),

                      _GenreSection(
                        selected: st.genre,
                        onSelect: ctrl.selectGenre,
                        onMore: () => _showGenreMoreSheet(context, ref),
                      ),

                      const SizedBox(height: 14),

                      _AdvancedOptions(
                        expanded: st.advancedExpanded,
                        songName: st.songName,
                        vocalGender: st.vocalGender,
                        onToggle: ctrl.toggleAdvanced,
                        onSongNameChanged: ctrl.setSongName,
                        onGenderChanged: ctrl.setVocalGender,
                      ),

                      const SizedBox(height: 16),

                      _CreateButton(
                        text: st.mode == GenerationMode.description
                            ? 'Create with Description'
                            : 'Create with Lyrics',
                        onPressed: () {
                          // позже тут будет вызов usecase/createJob
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('TODO: create job')),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // нижняя навигация — как на макете (пока заглушка)
      bottomNavigationBar: const AppBottomNav(active: AppTab.create),
    );
  }
}

/// ---------- Widgets ----------

class _TopLogo extends StatelessWidget {
  const _TopLogo();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'PULSE',
      style: TextStyle(
        fontFamily: AppTypography.logoFamily,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final GenerationMode mode;
  final ValueChanged<GenerationMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDesc = mode == GenerationMode.description;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              text: 'Description mode',
              selected: isDesc,
              onTap: () => onChanged(GenerationMode.description),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ToggleChip(
              text: 'Lyrics mode',
              selected: !isDesc,
              onTap: () => onChanged(GenerationMode.lyrics),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0x55FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'NicoMoji',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String title;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _PromptCard({
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x22000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'NicoMoji',
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: TextField(
              minLines: 4,
              maxLines: 6,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'NicoMoji',
                fontSize: 14,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'NicoMoji',
                  fontSize: 14,
                  color: Color(0xAAFFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSection extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final VoidCallback onMore;

  const _MoodSection({
    required this.selected,
    required this.onSelect,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    const quickMoods = [
      'Happy',
      'Confident',
      'Motivational',
      'Melancholic',
      'Productivity',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Mood',
          style: TextStyle(
            fontFamily: 'NicoMoji',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in quickMoods)
              _Pill(
                text: m,
                selected: selected == m,
                onTap: () => onSelect(m),
              ),
            _Pill(
              text: 'More',
              selected: false,
              dark: true,
              onTap: onMore,
            ),
          ],
        ),
      ],
    );
  }
}

class _GenreSection extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final VoidCallback onMore;

  const _GenreSection({
    required this.selected,
    required this.onSelect,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    const quickGenres = [
      ('Rock', AppAssets.genreRock),
      ('Blues', AppAssets.genreBlues),
      ('Jazz', AppAssets.genreJazz),
      ('Cinematic', AppAssets.genreCinematic),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Genre',
          style: TextStyle(
            fontFamily: 'NicoMoji',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final pair in quickGenres)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _SquareGenre(
                    label: pair.$1,
                    iconAsset: pair.$2,
                    selected: selected == pair.$1,
                    onTap: () => onSelect(pair.$1),
                  ),
                ),
              ),
            _SquareGenre(
              label: 'More',
              iconAsset: AppAssets.genreMore,
              selected: false,
              dark: true,
              onTap: onMore,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdvancedOptions extends StatelessWidget {
  final bool expanded;
  final String songName;
  final VocalGender? vocalGender;
  final VoidCallback onToggle;
  final ValueChanged<String> onSongNameChanged;
  final ValueChanged<VocalGender?> onGenderChanged;

  const _AdvancedOptions({
    required this.expanded,
    required this.songName,
    required this.vocalGender,
    required this.onToggle,
    required this.onSongNameChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onToggle,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Row(
              children: [
                const AppIcon(AppAssets.advanced, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Advanced Options',
                    style: TextStyle(
                      fontFamily: 'NicoMoji',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Song Name',
                    style: TextStyle(
                      fontFamily: 'NicoMoji',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: onSongNameChanged,
                      style: const TextStyle(
                        fontFamily: 'NicoMoji',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Type here...',
                        hintStyle: TextStyle(
                          fontFamily: 'NicoMoji',
                          fontSize: 14,
                          color: Color(0xAAFFFFFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Vocal Gender',
                    style: TextStyle(
                      fontFamily: 'NicoMoji',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _GenderTile(
                          label: 'man',
                          iconAsset: AppAssets.genderMan,
                          selected: vocalGender == VocalGender.man,
                          onTap: () => onGenderChanged(VocalGender.man),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GenderTile(
                          label: 'woman',
                          iconAsset: AppAssets.genderWoman,
                          selected: vocalGender == VocalGender.woman,
                          onTap: () => onGenderChanged(VocalGender.woman),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _GenderTile extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  const _GenderTile({
    required this.label,
    required this.iconAsset,
    required this.selected,
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
          color: selected ? const Color(0x55FFFFFF) : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(iconAsset, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _CreateButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0x33000000),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'NicoMoji',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _Pill({
    required this.text,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark
        ? const Color(0x88000000)
        : selected
        ? const Color(0x55FFFFFF)
        : const Color(0x22FFFFFF);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'NicoMoji',
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SquareGenre extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _SquareGenre({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark
        ? const Color(0x88000000)
        : selected
        ? const Color(0x55FFFFFF)
        : const Color(0x22FFFFFF);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(iconAsset, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
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

// class _BottomBarStub extends StatelessWidget {
//   const _BottomBarStub();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 88,
//       decoration: const BoxDecoration(color: Color(0x33000000)),
//       child: const Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _BottomItem(label: 'AI COVER', asset: AppAssets.navAiCover),
//           _BottomItem(label: 'CREATE', asset: AppAssets.navCreate),
//           _BottomItem(label: 'LIBRARY', asset: AppAssets.navLibrary),
//         ],
//       ),
//     );
//   }
// }
//
// class _BottomItem extends StatelessWidget {
//   final String label;
//   final String asset;
//
//   const _BottomItem({required this.label, required this.asset});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         AppIcon(asset, size: 30),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: const TextStyle(
//             fontFamily: AppTypography.fontFamily,
//             fontSize: 12,
//             color: Colors.white,
//           ),
//         ),
//       ],
//     );
//   }
// }

/// ---------- Bottom sheets ----------

Future<void> _showMoodMoreSheet(BuildContext context, WidgetRef ref) async {
  const moods = [
    'Happy',
    'Confident',
    'Motivational',
    'Melancholic',
    'Productivity',
    'Party',
    'Dark',
    'Passionate',
    'Soft',
    'Joyful',
    'Weird',
    'Spiritual',
    'Romantic',
    'Dreamy',
    'Chill',
    'Whimsical',
    'Magical',
    'Emotional',
    'Lyrical',
    'Hype',
  ];

  final ctrl = ref.read(generationFormProvider.notifier);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _SheetContainer(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Select Mood',
              style: TextStyle(
                fontFamily: 'NicoMoji',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in moods)
                      _Pill(
                        text: m,
                        selected: false,
                        onTap: () => ctrl.selectMood(m),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x55FFFFFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontFamily: 'NicoMoji', fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showGenreMoreSheet(BuildContext context, WidgetRef ref) async {
  const genres = [
    'Rock',
    'Blues',
    'Jazz',
    'Cinematic',
    'Funk',
    'Rap',
    'Pop',
    'Classical',
    'Metal',
    'K-Pop',
    'Indie',
    'Hip-Hop',
    'Country',
    'Latin',
    'Dance',
    'Soul',
    'Lullaby',
    'Celtic',
    'Trance',
  ];

  final ctrl = ref.read(generationFormProvider.notifier);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _SheetContainer(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Select Genre',
              style: TextStyle(
                fontFamily: 'NicoMoji',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final g in genres)
                      _Pill(
                        text: g,
                        selected: false,
                        onTap: () => ctrl.selectGenre(g),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x55FFFFFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontFamily: 'NicoMoji', fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SheetContainer extends StatelessWidget {
  final Widget child;
  const _SheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.62,
      decoration: const BoxDecoration(
        color: Color(0xAA120026),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: child,
    );
  }
}