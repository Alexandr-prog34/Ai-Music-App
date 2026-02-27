import 'job.dart';

enum WsType {
  jobUpdated('job_updated'),
  pong('pong'),
  error('error');

  final String value;

  const WsType(this.value);

  factory WsType.fromJson(String value) {
    return WsType.values.firstWhere(
      (e) {
        return e.value == value;
      },
    );
  }

  String toJson() {
    return value;
  }
}

class WsMessage {
  final WsType type;
  final Job? job;
  final Map<String, dynamic>? error;

  WsMessage({
    required this.type,
    this.job,
    this.error,
  });

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    final type = WsType.fromJson(json['type'] as String);

    if (type == WsType.jobUpdated) {
      return WsMessage(
        type: type,
        job: Job.fromJson(json['data'] as Map<String, dynamic>),
      );
    }

    if (type == WsType.error) {
      return WsMessage(
        type: type,
        error: json['data'] as Map<String, dynamic>?,
      );
    }

    return WsMessage(
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'type': type.toJson(),
    };

    if (job != null) {
      json['data'] = job!.toJson();
    }

    if (error != null) {
      json['data'] = error;
    }

    return json;
  }
}