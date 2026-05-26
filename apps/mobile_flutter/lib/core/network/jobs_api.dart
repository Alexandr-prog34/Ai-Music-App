import 'package:dio/dio.dart';

import '../../shared/domain/create_job_request.dart';
import '../../shared/domain/job.dart';
import '../../shared/domain/job_status.dart';

class JobsApi {
  final Dio dio;

  JobsApi(this.dio);

  //POST /jobs
  Future<Job> createJob(CreateJobRequest request) async {
    final response = await dio.post(
      "/jobs",
      data: request.toJson(),
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Empty response when creating job',
      );
    }

    return Job.fromJson(
      data as Map<String, dynamic>,
    );
  }

  //GET /jobs
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

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Empty response when listing jobs',
      );
    }

    final map = data as Map<String, dynamic>;

    final items = (map["items"] as List?) ?? [];

    return items
        .map(
          (json) => Job.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  //GET /jobs/{id}
  Future<Job> getJob(String id) async {
    final response = await dio.get("/jobs/$id");

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Empty response when getting job',
      );
    }

    return Job.fromJson(
      data as Map<String, dynamic>,
    );
  }
}