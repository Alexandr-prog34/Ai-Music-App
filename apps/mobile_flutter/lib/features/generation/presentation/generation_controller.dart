import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device_id/device_id_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/jobs_api.dart';
import '../../../core/network/websocket_api.dart';

import '../../../shared/domain/create_job_request.dart';
import '../../../shared/domain/job.dart';
import '../../../shared/domain/suno_model.dart';
import '../../../shared/domain/vocal_gender.dart' as shared;

import '../data/repositories/generation_repository_impl.dart';
import '../domain/usecases/create_job_usecase.dart';
import '../domain/usecases/listen_jobs_usecase.dart';

enum GenerationMode {
  description,
  lyrics,
}

enum VocalGender {
  man,
  woman,
}

class GenerationFormState {
  final GenerationMode mode;

  final String promptText;

  final String? mood;
  final String? genre;

  final bool advancedExpanded;

  final String songName;

  final VocalGender? vocalGender;

  final bool instrumental;

  final bool isSubmitting;

  final String? errorMessage;
  final String? completedTrackId;

  const GenerationFormState({
    required this.mode,
    required this.promptText,
    required this.mood,
    required this.genre,
    required this.advancedExpanded,
    required this.songName,
    required this.vocalGender,
    required this.instrumental,
    this.isSubmitting = false,
    this.errorMessage,
    this.completedTrackId,
  });

  factory GenerationFormState.initial() =>
      const GenerationFormState(
        mode: GenerationMode.description,
        promptText: '',
        mood: null,
        genre: null,
        advancedExpanded: false,
        songName: '',
        vocalGender: null,
        instrumental: false,
      );

  GenerationFormState copyWith({
    GenerationMode? mode,
    String? promptText,
    String? Function()? mood,
    String? Function()? genre,
    bool? advancedExpanded,
    String? songName,
    VocalGender? Function()? vocalGender,
    bool? instrumental,
    bool? isSubmitting,
    String? Function()? errorMessage,
    String? Function()? completedTrackId,
  }) {
    return GenerationFormState(
      mode: mode ?? this.mode,
      promptText: promptText ?? this.promptText,
      mood: mood != null ? mood() : this.mood,
      genre: genre != null ? genre() : this.genre,
      advancedExpanded:
          advancedExpanded ?? this.advancedExpanded,
      songName: songName ?? this.songName,
      vocalGender:
          vocalGender != null
              ? vocalGender()
              : this.vocalGender,
      instrumental:
          instrumental ?? this.instrumental,
      isSubmitting:
          isSubmitting ?? this.isSubmitting,
      errorMessage:
          errorMessage != null
              ? errorMessage()
              : this.errorMessage,
      completedTrackId:
          completedTrackId != null
              ? completedTrackId()
              : this.completedTrackId,
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

class GenerationFormController
    extends Notifier<GenerationFormState> {

  StreamSubscription<Job>? _subscription;

  @override
  GenerationFormState build() {

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return GenerationFormState.initial();
  }

  void setMode(GenerationMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setPromptText(String value) {
    state = state.copyWith(promptText: value);
  }

  void selectMood(String? value) {

    final next =
        state.mood == value ? null : value;

    state = state.copyWith(
      mood: () => next,
    );
  }

  void selectGenre(String? value) {

    final next =
        state.genre == value ? null : value;

    state = state.copyWith(
      genre: () => next,
    );
  }

  void toggleAdvanced() {

    state = state.copyWith(
      advancedExpanded:
          !state.advancedExpanded,
    );
  }

  void setSongName(String value) {
    state = state.copyWith(
      songName: value,
    );
  }

  void setVocalGender(VocalGender? value) {
    state = state.copyWith(
      vocalGender: () => value,
    );
  }

  void setInstrumental(bool value) {
    state = state.copyWith(
      instrumental: value,
    );
  }

  void clearError() {
    state = state.copyWith(
      errorMessage: () => null,
    );
  }

  void clearCompletedTrack() {
    state = state.copyWith(
      completedTrackId: () => null,
    );
  }

  Future<Job?> submit() async {

    final error = state.validate();

    if (error != null) {

      state = state.copyWith(
        errorMessage: () => error,
      );

      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: () => null,
    );

    try {

      /// DEVICE ID
      final deviceId =
          await DeviceIdService.instance.getDeviceId();

      /// DIO
      final dio = createDio(deviceId);

      /// API
      final jobsApi = JobsApi(dio);

      final host = (Uri.parse('http://localhost').host);
      final wsHost = {
        true: '10.0.2.2',
        false: host,
      }[Platform.isAndroid] ?? host;

      final wsApi = WebSocketApi(
        'ws://$wsHost:8080/ws?device_id=$deviceId',
      );

      /// REPOSITORY
      final repository =
          GenerationRepositoryImpl(
        jobsApi,
        wsApi,
      );

      /// USECASE
      final createJobUseCase =
          CreateJobUseCase(repository);

      final listenJobsUseCase =
          ListenJobsUseCase(repository);

      final usesAdvancedOptions =
          state.songName.trim().isNotEmpty ||
          state.vocalGender != null ||
          state.instrumental;
      final customMode =
          state.mode == GenerationMode.lyrics ||
          usesAdvancedOptions;
      final styleParts = [
        if (state.mood != null) state.mood!,
        if (state.genre != null) state.genre!,
      ];
      final style = styleParts.isEmpty ? 'music' : styleParts.join(', ');
      final title = state.songName.trim().isEmpty
          ? 'Untitled track'
          : state.songName.trim();

      /// REQUEST
      final request = CreateJobRequest(

        prompt: state.promptText.trim(),

        customMode: customMode,

        style: customMode ? style : null,

        instrumental:
            state.instrumental,

        vocalGender:
            customMode
                ? (
                    state.vocalGender ==
                            VocalGender.man
                        ? shared.VocalGender.m
                        : state.vocalGender ==
                                VocalGender.woman
                            ? shared.VocalGender.f
                            : null
                  )
                : null,

        model: SunoModel.V4_5ALL,

        title: customMode ? title : null,
      );

      /// CREATE JOB
      final createdJob =
          await createJobUseCase(request);

      print('SUCCESS');
      print(createdJob.id);
      print(createdJob.status);

      /// WEBSOCKET LISTENER
      _subscription?.cancel();

      _subscription =
        listenJobsUseCase().listen((job) {

      if (job.id != createdJob.id) {
        return;
      }

      print('WS UPDATE');

      print(job.id);

      print(job.status);

      /// COMPLETED
      if (
        job.status.name == 'ready'
      ) {

        state = state.copyWith(
          isSubmitting: false,
          completedTrackId: () => job.tracks?.isNotEmpty == true
              ? job.tracks!.first.id
              : null,
        );

        _subscription?.cancel();
      }

      /// FAILED
      if (
        job.status.name == 'failed'
      ) {

        state = state.copyWith(
          isSubmitting: false,

          errorMessage: () =>
              job.error ?? 'Generation failed',
        );

        _subscription?.cancel();
      }
    });

      // /// RESET FORM
      // state = GenerationFormState.initial();

      return createdJob;

    } catch (e) {

      print(e);

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => e.toString(),
      );

      return null;
    }
  }
}

final generationFormProvider =
    NotifierProvider<
      GenerationFormController,
      GenerationFormState
    >(
  GenerationFormController.new,
);
