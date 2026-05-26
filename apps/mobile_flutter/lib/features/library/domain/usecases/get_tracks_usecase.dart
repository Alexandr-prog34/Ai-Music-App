import '../repositories/tracks_repository.dart';
import '../../../../shared/domain/track.dart';

class GetTracksUseCase {

  final TracksRepository repository;

  GetTracksUseCase(this.repository);

  Future<List<Track>> call() {
    return repository.listTracks();
  }

}