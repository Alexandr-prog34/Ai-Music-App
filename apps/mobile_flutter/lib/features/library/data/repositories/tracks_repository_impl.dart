import '../../../../../core/network/tracks_api.dart';

import '../../../../../shared/domain/track.dart';

import '../../domain/repositories/tracks_repository.dart';

class TracksRepositoryImpl implements TracksRepository {

  final TracksApi tracksApi;

  TracksRepositoryImpl(
    this.tracksApi,
  );

  @override
  Future<List<Track>> listTracks() {
    return tracksApi.listTracks();
  }

  @override
  Future<Track> getTrack(
    String id,
  ) {
    return tracksApi.getTrack(id);
  }

  @override
  Future<void> deleteTrack(String id) {
    return tracksApi.deleteTrack(id);
  }

  @override
  Future<void> addFavorite(String id) {
    return tracksApi.addFavorite(id);
  }

  @override
  Future<void> removeFavorite(String id) {
    return tracksApi.removeFavorite(id);
  }

}