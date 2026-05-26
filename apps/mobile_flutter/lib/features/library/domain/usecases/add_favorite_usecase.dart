import '../repositories/tracks_repository.dart';

class AddFavoriteUseCase {

  final TracksRepository repository;

  AddFavoriteUseCase(this.repository);

  Future<void> call(String id) {
    return repository.addFavorite(id);
  }

}