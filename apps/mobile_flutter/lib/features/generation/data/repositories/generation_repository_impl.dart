import '../../../../core/network/jobs_api.dart';
import '../../../../core/network/websocket_api.dart';

import '../../../../shared/domain/create_job_request.dart';
import '../../../../shared/domain/job.dart';
import '../../../../shared/domain/ws_message.dart';

import '../../domain/repositories/generation_repository.dart';

class GenerationRepositoryImpl implements GenerationRepository {

  final JobsApi jobsApi;
  final WebSocketApi wsApi;

  GenerationRepositoryImpl(
    this.jobsApi,
    this.wsApi,
  );

  @override
  Future<Job> createJob(CreateJobRequest request) {
    return jobsApi.createJob(request);
  }

  @override
  Future<List<Job>> listJobs() {
    return jobsApi.listJobs();
  }

  @override
  Future<Job> getJob(String id) {
    return jobsApi.getJob(id);
  }

  @override
  Stream<Job> listenJobs() {

    return wsApi.connect()

        .where(
          (message) => message.type == WsType.jobUpdated && message.job != null,
        )

        .map(
          (message) => message.job!,
        );

  }

}
