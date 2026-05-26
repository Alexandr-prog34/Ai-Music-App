import '../../../../shared/domain/track.dart';

abstract class TracksRepository {

  Future<List<Track>> listTracks();

  Future<Track> getTrack(String id);

  Future<void> deleteTrack(String id);

  Future<void> addFavorite(String id);

  Future<void> removeFavorite(String id);

}