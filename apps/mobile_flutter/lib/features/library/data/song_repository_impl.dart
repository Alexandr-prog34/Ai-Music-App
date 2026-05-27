import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device_id/device_id_service.dart';
import '../../../core/models/song.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/tracks_api.dart';
import '../../../core/repositories/song_repository.dart';
import '../../../shared/domain/track.dart';

class BackendSongRepository implements SongRepository {
  Future<TracksApi> _api() async {
    final deviceId = await DeviceIdService.instance.getDeviceId();
    return TracksApi(createDio(deviceId));
  }

  @override
  Future<List<Song>> getAll() async {
    final tracks = await (await _api()).listTracks(limit: 100);
    return tracks.map(_songFromTrack).toList();
  }

  @override
  Future<Song?> getById(String id) async {
    try {
      return _songFromTrack(await (await _api()).getTrack(id));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Song> save(Song song) async {
    if (song.id.isEmpty) {
      throw StateError('Songs are created through generation jobs');
    }
    return song;
  }

  @override
  Future<void> delete(String id) async {
    await (await _api()).deleteTrack(id);
  }

  @override
  Future<Set<String>> getLikedIds() async {
    final tracks = await (await _api()).listTracks(favorite: true, limit: 100);
    return tracks.map((track) => track.id).toSet();
  }

  @override
  Future<bool> toggleLike(String songId) async {
    final api = await _api();
    final track = await api.getTrack(songId);
    if (track.isFavorite) {
      await api.removeFavorite(songId);
      return false;
    }
    await api.addFavorite(songId);
    return true;
  }

  Song _songFromTrack(Track track) {
    return Song(
      id: track.id,
      title: track.title,
      genre: track.tags,
      coverPath: track.imageUrl,
      streamUrl: track.streamUrl,
      audioUrl: track.audioUrl,
      duration: Duration(milliseconds: (track.durationSec * 1000).round()),
      createdAt: track.createdAt,
    );
  }
}

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return BackendSongRepository();
});
