import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/repositories/playlist_repository.dart';

/// In-memory implementation of [PlaylistRepository].
class InMemoryPlaylistRepository implements PlaylistRepository {
  final Map<String, Playlist> _playlists = {};
  int _nextId = 1;

  @override
  Future<List<Playlist>> getAll() async {
    final list = _playlists.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Playlist?> getById(String id) async => _playlists[id];

  @override
  Future<Playlist> create(String name) async {
    final playlist = Playlist(
      id: '${_nextId++}',
      name: name,
      createdAt: DateTime.now(),
    );
    _playlists[playlist.id] = playlist;
    return playlist;
  }

  @override
  Future<Playlist> update(Playlist playlist) async {
    _playlists[playlist.id] = playlist;
    return playlist;
  }

  @override
  Future<void> delete(String id) async => _playlists.remove(id);

  @override
  Future<Playlist> addSong(String playlistId, String songId) async {
    final playlist = _playlists[playlistId];
    if (playlist == null) throw StateError('Playlist $playlistId not found');
    if (playlist.songIds.contains(songId)) return playlist;

    final updated = playlist.copyWith(
      songIds: [...playlist.songIds, songId],
    );
    _playlists[playlistId] = updated;
    return updated;
  }

  @override
  Future<Playlist> removeSong(String playlistId, String songId) async {
    final playlist = _playlists[playlistId];
    if (playlist == null) throw StateError('Playlist $playlistId not found');

    final updated = playlist.copyWith(
      songIds: playlist.songIds.where((id) => id != songId).toList(),
    );
    _playlists[playlistId] = updated;
    return updated;
  }
}

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return InMemoryPlaylistRepository();
});
