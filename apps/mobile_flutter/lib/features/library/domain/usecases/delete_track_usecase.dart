import '../repositories/tracks_repository.dart';

class DeleteTrackUseCase {

  final TracksRepository repository;

  DeleteTrackUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteTrack(id);
  }

}