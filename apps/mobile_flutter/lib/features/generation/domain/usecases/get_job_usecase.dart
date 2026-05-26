import '../repositories/generation_repository.dart';
import '../../../../shared/domain/job.dart';

class GetJobUseCase {

  final GenerationRepository repository;

  GetJobUseCase(this.repository);

  Future<Job> call(String id) {
    return repository.getJob(id);
  }

}