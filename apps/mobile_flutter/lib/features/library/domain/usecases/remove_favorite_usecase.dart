import '../repositories/tracks_repository.dart';

class RemoveFavoriteUseCase {

  final TracksRepository repository;

  RemoveFavoriteUseCase(this.repository);

  Future<void> call(String id) {
    return repository.removeFavorite(id);
  }

}