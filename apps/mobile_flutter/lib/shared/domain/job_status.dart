enum JobStatus {
  queued('queued'),
  processing('processing'),
  ready('ready'),
  failed('failed');

  final String value;

  const JobStatus(this.value);

  factory JobStatus.fromJson(String? value) {
    if (value == null) {
      throw const FormatException(
        'JobStatus is null',
      );
    }
    return JobStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException(
        'Invalid JobStatus: $value',
      ),
    );
  }

  String toJson() {
    return value;
  }
}