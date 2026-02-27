Dio createDio(String deviceId) {
  return Dio(
    BaseOptions(
      baseUrl: "http://localhost:8080",
      headers: {
        "X-Device-Id": deviceId,
        "Content-Type": "application/json",
      },
    ),
  );
}