import '../repositories/generation_repository.dart';
import '../../../../shared/domain/job.dart';

class ListenJobsUseCase {

  final GenerationRepository repository;

  ListenJobsUseCase(this.repository);

  Stream<Job> call() {
    return repository.listenJobs();
  }

}