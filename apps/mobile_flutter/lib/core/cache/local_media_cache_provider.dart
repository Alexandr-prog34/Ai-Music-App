import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_media_cache.dart';

/// Provider for LocalMediaCache initialization
final localMediaCacheProvider = FutureProvider<LocalMediaCache>((ref) async {
  await localMediaCache.init();
  return localMediaCache;
});

/// Provider for getting cached audio file path
/// Returns the local file path, or null if download fails
final cachedAudioProvider =
    FutureProvider.family<String?, String>((ref, url) async {
  final cache = await ref.watch(localMediaCacheProvider.future);
  return cache.getCachedAudio(url);
});

/// Provider for getting cached image file path
/// Returns the local file path, or null if download fails
final cachedImageProvider =
    FutureProvider.family<String?, String>((ref, url) async {
  final cache = await ref.watch(localMediaCacheProvider.future);
  return cache.getCachedImage(url);
});
