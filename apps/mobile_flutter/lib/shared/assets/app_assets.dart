/// Centralised asset paths.
///
/// Every image reference goes through this class so that a typo in a path
/// is caught at compile-time, not at runtime.
class AppAssets {
  AppAssets._();

  // Advanced options
  static const advanced = 'assets/icons/advanced.png';

  // Gender
  static const genderMan = 'assets/icons/gender_man.png';
  static const genderWoman = 'assets/icons/gender_woman.png';

  // Genres
  static const genreRock = 'assets/icons/genre_rock.png';
  static const genreBlues = 'assets/icons/genre_blues.png';
  static const genreJazz = 'assets/icons/genre_jazz.png';
  static const genreCinematic = 'assets/icons/genre_cinematic.png';
  static const genreMore = 'assets/icons/genre_more.png';

  // Bottom nav
  static const navCreate = 'assets/icons/nav_create.png';
  static const navLibrary = 'assets/icons/nav_library.png';

  // Library
  static const librarySearch = 'assets/icons/library_search.png';
  static const libraryFavorites = 'assets/icons/library_favorites.png';
  static const libraryAddPlaylist = 'assets/icons/library_add_playlist.png';
  static const libraryArrow = 'assets/icons/library_arrow.png';
}
