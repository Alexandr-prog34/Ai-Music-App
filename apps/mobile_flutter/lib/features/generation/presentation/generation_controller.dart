import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GenerationMode { description, lyrics }
enum VocalGender { man, woman }

class GenerationFormState {
  final GenerationMode mode;
  final String promptText;
  final String? mood;
  final String? genre;
  final bool advancedExpanded;

  final String songName;
  final VocalGender? vocalGender;

  const GenerationFormState({
    required this.mode,
    required this.promptText,
    required this.mood,
    required this.genre,
    required this.advancedExpanded,
    required this.songName,
    required this.vocalGender,
  });

  factory GenerationFormState.initial() => const GenerationFormState(
    mode: GenerationMode.description,
    promptText: '',
    mood: null,
    genre: null,
    advancedExpanded: false,
    songName: '',
    vocalGender: null,
  );

  GenerationFormState copyWith({
    GenerationMode? mode,
    String? promptText,
    String? mood,
    String? genre,
    bool? advancedExpanded,
    String? songName,
    VocalGender? vocalGender,
  }) {
    return GenerationFormState(
      mode: mode ?? this.mode,
      promptText: promptText ?? this.promptText,
      mood: mood ?? this.mood,
      genre: genre ?? this.genre,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
      songName: songName ?? this.songName,
      vocalGender: vocalGender ?? this.vocalGender,
    );
  }
}

class GenerationFormController extends Notifier<GenerationFormState> {
  @override
  GenerationFormState build() => GenerationFormState.initial();

  void setMode(GenerationMode mode) => state = state.copyWith(mode: mode);
  void setPromptText(String v) => state = state.copyWith(promptText: v);

  void selectMood(String? v) => state = state.copyWith(mood: v);
  void selectGenre(String? v) => state = state.copyWith(genre: v);

  void toggleAdvanced() =>
      state = state.copyWith(advancedExpanded: !state.advancedExpanded);

  void setSongName(String v) => state = state.copyWith(songName: v);
  void setVocalGender(VocalGender? v) => state = state.copyWith(vocalGender: v);
}

final generationFormProvider =
NotifierProvider<GenerationFormController, GenerationFormState>(
  GenerationFormController.new,
);