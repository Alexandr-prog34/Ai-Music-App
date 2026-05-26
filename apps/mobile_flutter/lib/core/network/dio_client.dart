import 'package:dio/dio.dart';

Dio createDio(String deviceId) {
  final dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:8080",
      headers: {
        "X-Device-Id": deviceId,
        "Content-Type": "application/json",
      },
    ),
  );

  //логирование
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
    ),
  );

  return dio;
}