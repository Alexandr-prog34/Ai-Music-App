class Track {
  final String id;
  final String jobId;
  final String sunoAudioId;
  final String title;
  final String? tags;
  final double durationSec;
  final String audioUrl;
  final String? streamUrl;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime createdAt;

  const Track({
    required this.id,
    required this.jobId,
    required this.sunoAudioId,
    required this.title,
    this.tags,
    required this.durationSec,
    required this.audioUrl,
    this.streamUrl,
    this.imageUrl,
    required this.isFavorite,
    required this.createdAt,
  });


  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,

      jobId: json['job_id'] as String,

      sunoAudioId: json['suno_audio_id'] as String,

      title: json['title'] as String,

      tags: json['tags'] as String?,

      durationSec: (json['duration_sec'] as num).toDouble(),

      audioUrl: json['audio_url'] as String,

      streamUrl: json['stream_url'] as String?,

      imageUrl: json['image_url'] as String?,

      isFavorite: json['is_favorite'] as bool,

      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'suno_audio_id': sunoAudioId,
      'title': title,
      'tags': tags,
      'duration_sec': durationSec,
      'audio_url': audioUrl,
      'stream_url': streamUrl,
      'image_url': imageUrl,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
    };
  }
}