import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../core/repositories/song_repository.dart';

/// In-memory implementation of [SongRepository].
///
/// Seeds two stub songs so the UI isn't empty on first launch.
/// Replace this class with a real persistence layer (SQLite, Hive, API)
/// when the backend is ready — the rest of the app won't change.
class InMemorySongRepository implements SongRepository {
  final Map<String, Song> _songs = {
    '1': Song(
      id: '1',
      title: 'Untitled #1',
      mood: 'Happy',
      genre: 'Rock',
      lyrics: 'Lyrics for Untitled #1...',
      duration: const Duration(minutes: 3, seconds: 24),
      createdAt: DateTime(2025, 1, 15),
    ),
    '2': Song(
      id: '2',
      title: 'Untitled #2',
      mood: 'Melancholic',
      genre: 'Jazz',
      lyrics: 'Lyrics for Untitled #2...',
      duration: const Duration(minutes: 4, seconds: 12),
      createdAt: DateTime(2025, 1, 20),
    ),
  };

  final Set<String> _likedIds = {};

  int _nextId = 3;

  @override
  Future<List<Song>> getAll() async {
    final list = _songs.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Song?> getById(String id) async => _songs[id];

  @override
  Future<Song> save(Song song) async {
    final saved = song.id.isEmpty
        ? Song(
            id: '${_nextId++}',
            title: song.title,
            mood: song.mood,
            genre: song.genre,
            lyrics: song.lyrics,
            coverPath: song.coverPath,
            duration: song.duration,
            createdAt: DateTime.now(),
          )
        : song;
    _songs[saved.id] = saved;
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    _songs.remove(id);
    _likedIds.remove(id);
  }

  @override
  Future<Set<String>> getLikedIds() async => Set.unmodifiable(_likedIds);

  @override
  Future<bool> toggleLike(String songId) async {
    if (_likedIds.contains(songId)) {
      _likedIds.remove(songId);
      return false;
    }
    _likedIds.add(songId);
    return true;
  }
}

/// Global provider — override this in tests or when switching to a real DB.
final songRepositoryProvider = Provider<SongRepository>((ref) {
  return InMemorySongRepository();
});
