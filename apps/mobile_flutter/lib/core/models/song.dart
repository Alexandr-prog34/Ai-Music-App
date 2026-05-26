/// Represents a single generated song.
class Song {
  final String id;
  final String title;
  final String? mood;
  final String? genre;
  final String? lyrics;
  final String? coverPath;
  final Duration duration;
  final DateTime createdAt;

  const Song({
    required this.id,
    required this.title,
    this.mood,
    this.genre,
    this.lyrics,
    this.coverPath,
    this.duration = Duration.zero,
    required this.createdAt,
  });

  Song copyWith({
    String? title,
    String? mood,
    String? genre,
    String? lyrics,
    String? coverPath,
    Duration? duration,
  }) {
    return Song(
      id: id,
      title: title ?? this.title,
      mood: mood ?? this.mood,
      genre: genre ?? this.genre,
      lyrics: lyrics ?? this.lyrics,
      coverPath: coverPath ?? this.coverPath,
      duration: duration ?? this.duration,
      createdAt: createdAt,
    );
  }
}
