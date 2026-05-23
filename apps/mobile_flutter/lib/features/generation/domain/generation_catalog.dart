/// Catalogues of available moods and genres.
///
/// These live in the domain layer so that both presentation and data layers
/// can reference them without circular imports.
class GenerationCatalog {
  GenerationCatalog._();

  /// Moods shown directly on the create screen (first 5).
  static const quickMoods = [
    'Happy',
    'Confident',
    'Motivational',
    'Melancholic',
    'Productivity',
  ];

  /// Full list shown in the "More" sheet.
  static const allMoods = [
    'Happy', 'Confident', 'Motivational', 'Melancholic', 'Productivity',
    'Party', 'Dark', 'Passionate', 'Soft', 'Joyful', 'Weird', 'Spiritual',
    'Romantic', 'Dreamy', 'Chill', 'Whimsical', 'Magical', 'Emotional',
    'Lyrical', 'Hype',
  ];

  /// Genres shown as square cards on the create screen.
  static const quickGenres = ['Rock', 'Blues', 'Jazz', 'Cinematic'];

  /// Full list shown in the "More" sheet.
  static const allGenres = [
    'Rock', 'Blues', 'Jazz', 'Cinematic', 'Funk', 'Rap', 'Pop', 'Classical',
    'Metal', 'K-Pop', 'Indie', 'Hip-Hop', 'Country', 'Latin', 'Dance',
    'Soul', 'Lullaby', 'Celtic', 'Trance',
  ];
}
