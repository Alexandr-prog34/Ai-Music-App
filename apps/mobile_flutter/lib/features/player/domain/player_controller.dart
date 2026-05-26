import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../library/data/song_repository_impl.dart';

/// The state exposed to the player screen.
class PlayerState {
  final Song song;
  final bool isPlaying;
  final bool isLiked;
  final double progress;

  const PlayerState({
    required this.song,
    this.isPlaying = false,
    this.isLiked = false,
    this.progress = 0,
  });

  PlayerState copyWith({
    Song? song,
    bool? isPlaying,
    bool? isLiked,
    double? progress,
  }) {
    return PlayerState(
      song: song ?? this.song,
      isPlaying: isPlaying ?? this.isPlaying,
      isLiked: isLiked ?? this.isLiked,
      progress: progress ?? this.progress,
    );
  }
}

/// Family-scoped: one controller per song ID.
final playerControllerProvider =
    AsyncNotifierProvider.family<PlayerController, PlayerState, String>(
  PlayerController.new,
);

class PlayerController extends FamilyAsyncNotifier<PlayerState, String> {
  @override
  Future<PlayerState> build(String arg) async {
    final repo = ref.read(songRepositoryProvider);
    final song = await repo.getById(arg);
    if (song == null) throw StateError('Song $arg not found');

    final likedIds = await repo.getLikedIds();

    return PlayerState(
      song: song,
      isLiked: likedIds.contains(arg),
    );
  }

  void togglePlay() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(isPlaying: !current.isPlaying));
  }

  void seek(double value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(progress: value.clamp(0, 1)));
  }

  Future<void> toggleLike() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = await AsyncValue.guard(() async {
      final liked = await ref
          .read(songRepositoryProvider)
          .toggleLike(current.song.id);
      return current.copyWith(isLiked: liked);
    });
  }

  Future<void> renameSong(String nextTitle) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = await AsyncValue.guard(() async {
      final repo = ref.read(songRepositoryProvider);
      final updated = current.song.copyWith(title: nextTitle);
      await repo.save(updated);
      return current.copyWith(song: updated);
    });
  }
}
