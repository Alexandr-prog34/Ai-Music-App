import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for caching media files (audio, images) locally.
/// 
/// Problem: presigned Minio localhost URLs cause issues with GStreamer on Linux.
/// Solution: download & cache files locally, then use file:// URLs.
class LocalMediaCache {
  static const String _audioSubdir = 'audio_cache';
  static const String _imageSubdir = 'image_cache';
  static const Duration _cacheTTL = Duration(days: 30);

  late final Directory _cacheDir;
  bool _initialized = false;

  /// Initialize the cache (must be called once at app startup).
  Future<void> init() async {
    if (_initialized) return;

    try {
      final tempDir = await getTemporaryDirectory();
      _cacheDir = Directory('${tempDir.path}/ai_music_cache');
      await _cacheDir.create(recursive: true);
      _initialized = true;
    } catch (e) {
      debugPrint('LocalMediaCache.init error: $e');
      rethrow;
    }
  }

  /// Get local file path for cached audio, downloading if necessary.
  /// Returns null if download fails.
  Future<String?> getCachedAudio(String url) async {
    if (!_initialized) throw StateError('LocalMediaCache not initialized');
    if (url.isEmpty) return null;

    try {
      final hash = _hashUrl(url);
      final audioDir = Directory('${_cacheDir.path}/$_audioSubdir');
      await audioDir.create(recursive: true);

      final filePath = '${audioDir.path}/$hash.mp3';
      final file = File(filePath);

      // Return cached file if exists and not expired
      if (await file.exists()) {
        final stat = await file.stat();
        final age = DateTime.now().difference(stat.modified);
        if (age < _cacheTTL) {
          return filePath;
        }
        // File expired, delete it
        await file.delete();
      }

      // Download file
      return await _downloadFile(url, filePath);
    } catch (e) {
      debugPrint('LocalMediaCache.getCachedAudio error: $e');
      return null;
    }
  }

  /// Get local file path for cached image, downloading if necessary.
  /// Returns null if download fails.
  Future<String?> getCachedImage(String url) async {
    if (!_initialized) throw StateError('LocalMediaCache not initialized');
    if (url.isEmpty) return null;

    try {
      final hash = _hashUrl(url);
      final imageDir = Directory('${_cacheDir.path}/$_imageSubdir');
      await imageDir.create(recursive: true);

      // Guess extension from URL or use .jpg as default
      final ext = _guessImageExtension(url);
      final filePath = '${imageDir.path}/$hash$ext';
      final file = File(filePath);

      // Return cached file if exists and not expired
      if (await file.exists()) {
        final stat = await file.stat();
        final age = DateTime.now().difference(stat.modified);
        if (age < _cacheTTL) {
          return filePath;
        }
        // File expired, delete it
        await file.delete();
      }

      // Download file
      return await _downloadFile(url, filePath);
    } catch (e) {
      debugPrint('LocalMediaCache.getCachedImage error: $e');
      return null;
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    if (!_initialized) return;
    try {
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('LocalMediaCache.clear error: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    if (!_initialized) return 0;
    try {
      if (!await _cacheDir.exists()) return 0;
      int size = 0;
      await for (final file in _cacheDir.list(recursive: true)) {
        if (file is File) {
          size += await file.length();
        }
      }
      return size;
    } catch (e) {
      debugPrint('LocalMediaCache.getCacheSize error: $e');
      return 0;
    }
  }

  /// Private helpers

  String _hashUrl(String url) {
    return sha256.convert(utf8.encode(url)).toString().substring(0, 16);
  }

  String _guessImageExtension(String url) {
    if (url.contains('.png')) return '.png';
    if (url.contains('.gif')) return '.gif';
    if (url.contains('.webp')) return '.webp';
    return '.jpg'; // Default
  }

  Future<String?> _downloadFile(String url, String filePath) async {
  try {
    // local file path
    if (!url.startsWith('http')) {
      return url;
    }

    // Android emulator localhost fix
    if (Platform.isAndroid) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }

    final httpClient = HttpClient();

    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      debugPrint('Failed to download $url: ${response.statusCode}');
      return null;
    }

    final file = File(filePath);
    final sink = file.openWrite();

    await for (final chunk in response) {
      sink.add(chunk);
    }

    await sink.close();
    httpClient.close();

    return filePath;
  } catch (e) {
    debugPrint('LocalMediaCache._downloadFile error: $e');
    return null;
  }
}

}

/// Singleton instance
final localMediaCache = LocalMediaCache();
