import 'vocal_gender.dart';
import 'suno_model.dart';
import 'error.dart';

class CreateJobRequest {
  static const int promptMinLength = 1;
  static const int promptMaxLength = 5000;
  static const int styleMaxLength = 1000;
  static const int titleMaxLength = 80;
  static const int negativeTagsMaxLength = 200;

  final String prompt;
  final bool customMode;
  final String? style;
  final String? title;
  final bool instrumental;
  final SunoModel model;
  final VocalGender? vocalGender;
  final String? negativeTags;

  CreateJobRequest({
    required this.prompt,
    this.customMode = false,
    this.style,
    this.title,
    this.instrumental = false,
    this.model = SunoModel.V4_5ALL,
    this.vocalGender,
    this.negativeTags,
  });

  Error? validate() {
    if (prompt.length < promptMinLength || prompt.length > promptMaxLength) {
      return const Error(
        code: 'INVALID_PROMPT',
        message: 'Prompt must be between 1 and 5000 characters',
      );
    }

    if (style != null && style!.length > styleMaxLength) {
      return const Error(
        code: 'INVALID_STYLE',
        message: 'Style must be <= 1000 characters',
      );
    }

    if (title != null && title!.length > titleMaxLength) {
      return const Error(
        code: 'INVALID_TITLE',
        message: 'Title must be <= 80 characters',
      );
    }

    if (negativeTags != null &&
        negativeTags!.length > negativeTagsMaxLength) {
      return const Error(
        code: 'INVALID_NEGATIVE_TAGS',
        message: 'Negative tags must be <= 200 characters',
      );
    }

    return null;
  }

  factory CreateJobRequest.fromJson(Map<String, dynamic> json) {
    return CreateJobRequest(
      prompt: json['prompt'] as String,
      customMode: json['custom_mode'] as bool? ?? false,
      style: json['style'] as String?,
      title: json['title'] as String?,
      instrumental: json['instrumental'] as bool? ?? false,
      model: json['model'] != null
          ? SunoModel.fromJson(json['model'] as String)
          : SunoModel.V4_5ALL,
      vocalGender: json['vocal_gender'] != null
          ? VocalGender.fromJson(json['vocal_gender'] as String)
          : null,
      negativeTags: json['negative_tags'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'custom_mode': customMode,
      'style': style,
      'title': title,
      'instrumental': instrumental,
      'model': model.name,
      'vocal_gender': vocalGender?.name,
      'negative_tags': negativeTags,
    };
  }
}
//в юзкейсе создать джоб потом проверить на валидность