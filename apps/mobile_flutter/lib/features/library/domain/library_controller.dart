import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/models/song.dart';
import '../data/playlist_repository_impl.dart';
import '../data/song_repository_impl.dart';

/// Provides the list of songs as an [AsyncValue] with automatic error handling.
final songsProvider = AsyncNotifierProvider<SongsController, List<Song>>(
  SongsController.new,
);

class SongsController extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() => _fetch();

  Future<List<Song>> _fetch() =>
      ref.read(songRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> delete(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(songRepositoryProvider).delete(id);
      return _fetch();
    });
  }

  Future<void> rename(String id, String newTitle) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(songRepositoryProvider);
      final song = await repo.getById(id);
      if (song == null) throw StateError('Song $id not found');
      await repo.save(song.copyWith(title: newTitle));
      return _fetch();
    });
  }
}

/// Provides all playlists as an [AsyncValue].
final playlistsProvider =
    AsyncNotifierProvider<PlaylistsController, List<Playlist>>(
  PlaylistsController.new,
);

class PlaylistsController extends AsyncNotifier<List<Playlist>> {
  @override
  Future<List<Playlist>> build() => _fetch();

  Future<List<Playlist>> _fetch() =>
      ref.read(playlistRepositoryProvider).getAll();

  Future<void> create(String name) async {
    state = await AsyncValue.guard(() async {
      await ref.read(playlistRepositoryProvider).create(name);
      return _fetch();
    });
  }

  Future<void> delete(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(playlistRepositoryProvider).delete(id);
      return _fetch();
    });
  }
}

/// Liked song IDs — thin async provider.
final likedSongIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.read(songRepositoryProvider).getLikedIds();
});
