import '../models/song.dart';

/// Contract for song persistence.
///
/// The presentation layer depends only on this interface, never on the
/// concrete storage mechanism. Swap [InMemorySongRepository] for an
/// SQLite / Hive / API-backed implementation later without touching UI.
abstract interface class SongRepository {
  /// Returns all songs the user has created, newest first.
  Future<List<Song>> getAll();

  /// Looks up a single song by [id]. Returns `null` when not found.
  Future<Song?> getById(String id);

  /// Persists a new or updated song and returns it.
  Future<Song> save(Song song);

  /// Permanently removes the song with the given [id].
  Future<void> delete(String id);

  /// Returns the IDs of songs the user has liked.
  Future<Set<String>> getLikedIds();

  /// Toggles the liked state of the given song.
  Future<bool> toggleLike(String songId);
}
