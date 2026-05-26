import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/assets/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/generation_catalog.dart';
import 'generation_controller.dart';

class GenerationScreen extends ConsumerWidget {
  const GenerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(generationFormProvider);
    final ctrl = ref.read(generationFormProvider.notifier);

    // Listen for error messages and show a SnackBar.
    ref.listen<GenerationFormState>(generationFormProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ctrl.clearError();
      }
    });

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
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 132),
                  sliver: SliverList.list(
                    children: [
                      _ModeToggle(mode: st.mode, onChanged: ctrl.setMode),
                      const SizedBox(height: 14),
                      _PromptCard(
                        title: st.mode == GenerationMode.description
                            ? 'Describe your track'
                            : 'Write your lyrics',
                        hint: st.mode == GenerationMode.description
                            ? 'Describe your track...'
                            : 'Type here...',
                        value: st.promptText,
                        onChanged: ctrl.setPromptText,
                      ),
                      const SizedBox(height: 18),
                      _MoodSection(
                        selected: st.mood,
                        onSelect: ctrl.selectMood,
                        onMore: () => _showMoodSheet(context, ref),
                      ),
                      const SizedBox(height: 14),
                      _GenreSection(
                        selected: st.genre,
                        onSelect: ctrl.selectGenre,
                        onMore: () => _showGenreSheet(context, ref),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 32, bottom: 18),
                        child: _CreateFooter(
                          label: st.mode == GenerationMode.description
                              ? 'Create with Description'
                              : 'Create with Lyrics',
                          isLoading: st.isSubmitting,
                          onPressed: () async {
                            final song = await ctrl.submit();
                            if (song != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Created "${song.title}"'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
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

// ─── Mode toggle ─────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final GenerationMode mode;
  final ValueChanged<GenerationMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDesc = mode == GenerationMode.description;
    return Container(
      height: 47,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: AppColors.toggleBackground,
      ),
      child: Row(
        children: [
          Expanded(child: _Tab(text: 'Description mode', selected: isDesc, onTap: () => onChanged(GenerationMode.description))),
          Expanded(child: _Tab(text: 'Lyrics Mode', selected: !isDesc, onTap: () => onChanged(GenerationMode.lyrics))),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF9C7BC6),
                    Color(0xFF7D55AE),
                    Color(0xFF642A88),
                  ],
                )
              : null,
          color: selected ? null : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0x73FFFFFF) : Colors.transparent,
            width: 0.6,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 24,
                    color: Color(0x333E145E),
                  ),
                ]
              : null,
        ),
        child: Text(text, style: AppTypography.tab),
      ),
    );
  }
}

// ─── Prompt card ─────────────────────────────────────────────────────────────

class _PromptCard extends StatelessWidget {
  final String title;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _PromptCard({required this.title, required this.hint, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.promptTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66543875),
                  Color(0x331E172A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.white10, width: 0.5),
            ),
            child: TextField(
              minLines: 4,
              maxLines: 6,
              onChanged: onChanged,
              style: AppTypography.body.copyWith(color: Colors.white),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTypography.body.copyWith(color: AppColors.white45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mood section ────────────────────────────────────────────────────────────

class _MoodSection extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final VoidCallback onMore;
  const _MoodSection({required this.selected, required this.onSelect, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Mood', style: AppTypography.title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in GenerationCatalog.quickMoods)
              _Pill(text: m, selected: selected == m, onTap: () => onSelect(m)),
            _Pill(text: 'More', selected: false, dark: true, onTap: onMore),
          ],
        ),
      ],
    );
  }
}

// ─── Genre section ───────────────────────────────────────────────────────────

class _GenreSection extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final VoidCallback onMore;
  const _GenreSection({required this.selected, required this.onSelect, required this.onMore});

  static const _icons = {
    'Rock': AppAssets.genreRock,
    'Blues': AppAssets.genreBlues,
    'Jazz': AppAssets.genreJazz,
    'Cinematic': AppAssets.genreCinematic,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Genre', style: AppTypography.title),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final label in GenerationCatalog.quickGenres)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _GenreCard(
                    label: label,
                    iconAsset: _icons[label] ?? AppAssets.genreMore,
                    selected: selected == label,
                    onTap: () => onSelect(label),
                  ),
                ),
              ),
            Expanded(
              child: _GenreCard(
                label: 'More',
                iconAsset: AppAssets.genreMore,
                selected: false,
                dark: true,
                onTap: onMore,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  const _GenreCard({required this.label, required this.iconAsset, required this.selected, required this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final gradient = dark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF785C91),
              Color(0xFF4A1E60),
            ],
          )
        : selected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x664F356F),
                  Color(0x88512D73),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x6631283F),
                  Color(0x441B1721),
                ],
              );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark
                ? const Color(0x66FFFFFF)
                : selected
                    ? const Color(0x40FFFFFF)
                    : AppColors.white10,
            width: 0.6,
          ),
          boxShadow: dark
              ? const [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 22,
                    color: Color(0x2D4D1D75),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(iconAsset, size: 26),
            const SizedBox(height: 6),
            Text(label, style: AppTypography.label.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Advanced options ────────────────────────────────────────────────────────

class _AdvancedOptions extends StatelessWidget {
  final bool expanded;
  final String songName;
  final VocalGender? vocalGender;
  final VoidCallback onToggle;
  final ValueChanged<String> onSongNameChanged;
  final ValueChanged<VocalGender?> onGenderChanged;

  const _AdvancedOptions({
    required this.expanded, required this.songName, required this.vocalGender,
    required this.onToggle, required this.onSongNameChanged, required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x664F356F),
                  Color(0x55301B4A),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.white10, width: 0.5),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 8),
                  blurRadius: 22,
                  color: Color(0x22000000),
                ),
              ],
            ),
            child: Row(
              children: [
                const AppIcon(AppAssets.advanced, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Advanced Options', style: AppTypography.button)),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white45, width: 0.8),
                  ),
                  child: Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Song Name',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x664B2F71),
                                Color(0x33201135),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.white10, width: 0.5),
                          ),
                          child: TextFormField(
                            initialValue: songName,
                            onChanged: onSongNameChanged,
                            style: AppTypography.body.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'Type here...',
                              hintStyle: AppTypography.body.copyWith(
                                color: AppColors.white40,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Vocal Gender',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _GenderTile(label: 'man', iconAsset: AppAssets.genderMan, selected: vocalGender == VocalGender.man, onTap: () => onGenderChanged(vocalGender == VocalGender.man ? null : VocalGender.man))),
                          const SizedBox(width: 12),
                          Expanded(child: _GenderTile(label: 'woman', iconAsset: AppAssets.genderWoman, selected: vocalGender == VocalGender.woman, onTap: () => onGenderChanged(vocalGender == VocalGender.woman ? null : VocalGender.woman))),
                        ]),
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
  const _GenderTile({required this.label, required this.iconAsset, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? const [
                    Color(0x88653A98),
                    Color(0x55402063),
                  ]
                : const [
                    Color(0x442F2344),
                    Color(0x331A1424),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0x669B6BEB) : AppColors.white10,
            width: 0.6,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(iconAsset, size: 22),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.label.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Create button with loading state ────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _CreateButton({required this.label, this.isLoading = false, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF785C91),
              Color(0xFF4A1E60),
            ],
          ),
          border: Border.all(color: const Color(0x2EFFFFFF), width: 0.6),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 12),
              blurRadius: 26,
              color: Color(0x2B000000),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: AppTypography.button),
      ),
    );
  }
}

class _CreateFooter extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _CreateFooter({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        _CreateButton(
          label: label,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class _DoneButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DoneButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 46,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF8A67B3),
              Color(0xFF9B73C8),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 8),
              blurRadius: 20,
              color: Color(0x332A1050),
            ),
          ],
        ),
        child: Text(
          'Done',
          style: AppTypography.button.copyWith(
            color: const Color(0xFF24104A),
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

// ─── Pill ────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  const _Pill({required this.text, required this.selected, required this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final gradient = dark
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF785C91),
              Color(0xFF4A1E60),
            ],
          )
        : selected
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x66503674),
                  Color(0x8A5C377E),
                ],
              )
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x6631283F),
                  Color(0x4D2A2237),
                ],
              );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: gradient,
          border: Border.all(
            color: dark
                ? const Color(0x59FFFFFF)
                : selected
                    ? const Color(0x2EFFFFFF)
                    : AppColors.white10,
            width: 0.6,
          ),
          boxShadow: dark
              ? const [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 22,
                    color: Color(0x29441B67),
                  ),
                ]
              : null,
        ),
        child: Text(text, style: AppTypography.body.copyWith(color: const Color(0xC9FFFFFF))),
      ),
    );
  }
}

// ─── Bottom sheets (data from catalog) ───────────────────────────────────────

Future<void> _showMoodSheet(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(generationFormProvider.notifier);
  final selected = ref.read(generationFormProvider).mood;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickerSheet(
      items: GenerationCatalog.allMoods,
      selected: selected,
      onSelect: ctrl.selectMood,
    ),
  );
}

Future<void> _showGenreSheet(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(generationFormProvider.notifier);
  final selected = ref.read(generationFormProvider).genre;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickerSheet(
      items: GenerationCatalog.allGenres,
      selected: selected,
      onSelect: ctrl.selectGenre,
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _PickerSheet({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.46;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(10, 0, 10, 106 + bottomInset),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xF018151D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white12, width: 0.6),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 28,
            color: Color(0x55000000),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in widget.items)
                    _Pill(
                      text: item,
                      selected: _selected == item,
                      onTap: () {
                        setState(() {
                          _selected = item;
                        });
                        widget.onSelect(item);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          _DoneButton(onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
