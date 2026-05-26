import '../repositories/generation_repository.dart';
import '../../../../shared/domain/job.dart';

class ListJobsUseCase {

  final GenerationRepository repository;

  ListJobsUseCase(this.repository);

  Future<List<Job>> call() {
    return repository.listJobs();
  }

}