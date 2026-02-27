enum JobStatus {
  queued('queued'),
  processing('processing'),
  ready('ready'),
  failed('failed');

  final String value;

  const JobStatus(this.value);

  factory JobStatus.fromJson(String? value) {
  return JobStatus.values.firstWhere(
    (e) => e.value == value,
    orElse: () => JobStatus.queued, // default(?)
  );
}

  String toJson() {
    return value;
  }
}