import '../models/playlist.dart';

/// Contract for playlist persistence.
abstract interface class PlaylistRepository {
  Future<List<Playlist>> getAll();
  Future<Playlist?> getById(String id);
  Future<Playlist> create(String name);
  Future<Playlist> update(Playlist playlist);
  Future<void> delete(String id);
  Future<Playlist> addSong(String playlistId, String songId);
  Future<Playlist> removeSong(String playlistId, String songId);
}
