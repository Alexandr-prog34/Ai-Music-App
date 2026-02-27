import 'package:dio/dio.dart';

import '../../shared/domain/create_job_request.dart';
import '../../shared/domain/job.dart';
import '../../shared/domain/job_status.dart';

class JobsApi {
  final Dio dio;

  JobsApi(this.dio);

  //POST /jobs
  //Создать новую задачу генерации
  Future<Job> createJob(CreateJobRequest request) async {
    final response = await dio.post(
      "/jobs",
      data: request.toJson(),
    );
    
    return Job.fromJson(response.data);
  }

  Future<List<Job>> listJobs({
    JobStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      "/jobs",
      queryParameters: {
        if (status != null) "status": status.toJson(),
        "limit": limit,
        "offset": offset,
      },
    );

    final items = (response.data["items"] as List?) ?? [];

    return items
        .map((json) => Job.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /jobs/{id}
  /// Получить конкретную задачу
  Future<Job> getJob(String id) async {
    final response = await dio.get("/jobs/$id");

    return Job.fromJson(response.data);
  }
}