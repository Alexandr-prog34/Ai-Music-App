import '../repositories/generation_repository.dart';
import '../../../../shared/domain/create_job_request.dart';
import '../../../../shared/domain/job.dart';

class CreateJobUseCase {

  final GenerationRepository repository;

  CreateJobUseCase(this.repository);

  Future<Job> call(CreateJobRequest request) async {

    final validationError = request.validate();

    if (validationError != null) {
      throw validationError;
    }

    return repository.createJob(request);
  }

}