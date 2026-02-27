import 'job_status.dart';
import 'track.dart';
import 'suno_model.dart';
import 'vocal_gender.dart'

class Job {
  final String id;
  final JobStatus status;
  final String prompt;
  final bool customMode;
  final String? style;
  final String? title;
  final bool instrumental;
  final SunoModel model;
  final VocalGender? vocalGender;
  final String? negativeTags;
  final String? sunoTaskId;
  final List<Track>? tracks;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  Job({
    required this.id,
    required this.status,
    required this.prompt,
    required this.customMode,
    this.style,
    this.title,
    required this.instrumental,
    required this.model,
    this.vocalGender,
    this.negativeTags,
    this.sunoTaskId,
    this.tracks,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json["id"] as String,

      status: JobStatus.fromJson(json["status"] as String?),

      prompt: json["prompt"] as String,

      customMode: json["custom_mode"] as bool? ?? false,

      style: json["style"] as String?,

      title: json["title"] as String?,

      instrumental: json["instrumental"] as bool? ?? false,

      model: SunoModel.fromJson(json["model"] as String?),

      vocalGender: VocalGender.fromJson(json["vocal_gender"] as String?),

      negativeTags: json["negative_tags"] as String?,

      sunoTaskId: json["suno_task_id"] as String?,

      tracks: (json["tracks"] as List?)
          ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),

      error: json["error"] as String?,

      createdAt: DateTime.parse(json["created_at"] as String),

      updatedAt: DateTime.parse(json["updated_at"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "status": status.toJson(),
      "prompt": prompt,
      "custom_mode": customMode,
      "style": style,
      "title": title,
      "instrumental": instrumental,
      "model": model.toJson(),
      "vocal_gender": vocalGender?.toJson(),
      "negative_tags": negativeTags,
      "suno_task_id": sunoTaskId,
      "tracks": tracks?.map((e) {
        return e.toJson();
      }).toList(),
      "error": error,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }
}