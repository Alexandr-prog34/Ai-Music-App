import '../../../../shared/domain/create_job_request.dart';
import '../../../../shared/domain/job.dart';

abstract class GenerationRepository {

  Future<Job> createJob(
    CreateJobRequest request,
  );

  Future<List<Job>> listJobs();

  Future<Job> getJob(String id);

  //WebSocket
  Stream<Job> listenJobs();

}