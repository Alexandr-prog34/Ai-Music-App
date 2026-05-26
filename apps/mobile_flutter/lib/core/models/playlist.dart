/// A user-created playlist that holds references to songs by their IDs.
class Playlist {
  final String id;
  final String name;
  final List<String> songIds;
  final String? coverPath;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.coverPath,
    required this.createdAt,
  });

  Playlist copyWith({
    String? name,
    List<String>? songIds,
    String? coverPath,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt,
    );
  }
}
