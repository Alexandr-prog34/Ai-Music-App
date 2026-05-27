import 'dart:io';

import 'package:dio/dio.dart';

String _backendHost(int port) {
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  return 'http://$host:$port';
}

Dio createDio(String deviceId) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _backendHost(8080),
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