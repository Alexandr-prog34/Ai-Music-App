import 'package:flutter/material.dart';

import 'core/network/dio_client.dart';
import 'core/network/jobs_api.dart';
import 'core/network/websocket_api.dart';

import 'features/generation/data/repositories/generation_repository_impl.dart';
import 'features/generation/domain/usecases/create_job_usecase.dart';

import 'shared/domain/create_job_request.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  const deviceId =
      "b664f848-3218-4075-8928-76f0bedb08a0";

  final dio = createDio(deviceId);

  /// API
  final jobsApi = JobsApi(dio);

  final wsApi =
      WebSocketApi(
        "ws://localhost:8080/ws?device_id=$deviceId",
      );

  /// Repository
  final repository =
      GenerationRepositoryImpl(
        jobsApi,
        wsApi,
      );

  /// UseCase
  final createJobUseCase =
      CreateJobUseCase(repository);

  /// TEST
  try {

    final job =
        await createJobUseCase(
      CreateJobRequest(
        prompt: "Test from UseCase",
        instrumental: true,
      ),
    );

    print("SUCCESS");
    print(job.id);
    print(job.status);

  } catch (e) {

    print("ERROR");
    print(e);

  }

}