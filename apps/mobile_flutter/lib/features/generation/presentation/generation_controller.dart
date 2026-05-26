import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../library/data/song_repository_impl.dart';
import '../../library/domain/library_controller.dart';

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
  final bool isSubmitting;
  final String? errorMessage;

  const GenerationFormState({
    required this.mode,
    required this.promptText,
    required this.mood,
    required this.genre,
    required this.advancedExpanded,
    required this.songName,
    required this.vocalGender,
    this.isSubmitting = false,
    this.errorMessage,
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
    String? Function()? mood,
    String? Function()? genre,
    bool? advancedExpanded,
    String? songName,
    VocalGender? Function()? vocalGender,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) {
    return GenerationFormState(
      mode: mode ?? this.mode,
      promptText: promptText ?? this.promptText,
      mood: mood != null ? mood() : this.mood,
      genre: genre != null ? genre() : this.genre,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
      songName: songName ?? this.songName,
      vocalGender: vocalGender != null ? vocalGender() : this.vocalGender,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  String? validate() {
    if (promptText.trim().isEmpty) {
      return mode == GenerationMode.description
          ? 'Please describe your track'
          : 'Please write some lyrics';
    }
    return null;
  }
}

class GenerationFormController extends Notifier<GenerationFormState> {
  @override
  GenerationFormState build() => GenerationFormState.initial();

  void setMode(GenerationMode mode) => state = state.copyWith(mode: mode);
  void setPromptText(String v) => state = state.copyWith(promptText: v);

  void selectMood(String? v) {
    final next = state.mood == v ? null : v;
    state = state.copyWith(mood: () => next);
  }

  void selectGenre(String? v) {
    final next = state.genre == v ? null : v;
    state = state.copyWith(genre: () => next);
  }

  void toggleAdvanced() =>
      state = state.copyWith(advancedExpanded: !state.advancedExpanded);

  void setSongName(String v) => state = state.copyWith(songName: v);

  void setVocalGender(VocalGender? v) =>
      state = state.copyWith(vocalGender: () => v);

  void clearError() => state = state.copyWith(errorMessage: () => null);

  /// Validates, saves via [SongRepository], refreshes library list.
  Future<Song?> submit() async {
    final error = state.validate();
    if (error != null) {
      state = state.copyWith(errorMessage: () => error);
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: () => null);

    try {
      final repo = ref.read(songRepositoryProvider);

      final title = state.songName.trim().isEmpty
          ? 'Untitled #${DateTime.now().millisecondsSinceEpoch % 10000}'
          : state.songName.trim();

      final song = await repo.save(Song(
        id: '',
        title: title,
        mood: state.mood,
        genre: state.genre,
        lyrics:
            state.mode == GenerationMode.lyrics ? state.promptText : null,
        createdAt: DateTime.now(),
      ));

      // Tell the library to re-fetch.
      ref.invalidate(songsProvider);

      // Reset form and explicitly mark as not submitting
      state = state.copyWith(isSubmitting: false);
      return song;
    } on Exception catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => e.toString(),
      );
      return null;
    }
  }
}

final generationFormProvider =
    NotifierProvider<GenerationFormController, GenerationFormState>(
  GenerationFormController.new,
);
