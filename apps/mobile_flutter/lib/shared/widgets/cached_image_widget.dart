import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/local_media_cache_provider.dart';

/// Widget for displaying cached images with fallback to network URLs
class CachedImageWidget extends ConsumerWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const CachedImageWidget({
    super.key,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    var normalizedUrl = imageUrl!;
    if (!normalizedUrl.contains('://')) {
      if (normalizedUrl.startsWith('//')) {
        normalizedUrl = 'http:$normalizedUrl';
      } else {
        normalizedUrl = 'http://$normalizedUrl';
      }
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      // Local file path
      return Image.file(
        File(normalizedUrl),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
      );
    }

    // Handle localhost -> 127.0.0.1 mapping for Linux
    if (uri.host == 'localhost') {
      if (Platform.isLinux) {
        normalizedUrl = uri.replace(host: '127.0.0.1').toString();
      } else if (Platform.isAndroid) {
        normalizedUrl = uri.replace(host: '10.0.2.2').toString();
      }
    }

    // On Linux: cache images locally for better performance
    if (Platform.isLinux) {
      return ref.watch(cachedImageProvider(normalizedUrl)).when(
        loading: () => placeholder ?? const SizedBox.shrink(),
        error: (_, __) => _buildNetworkImage(normalizedUrl, fit, width, height, placeholder),
        data: (cachedPath) {
          if (cachedPath != null) {
            return Image.file(
              File(cachedPath),
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, __, ___) => _buildNetworkImage(normalizedUrl, fit, width, height, placeholder),
            );
          }
          return _buildNetworkImage(normalizedUrl, fit, width, height, placeholder);
        },
      );
    }

    // For other platforms, use network image directly
    return _buildNetworkImage(normalizedUrl, fit, width, height, placeholder);
  }

  Widget _buildNetworkImage(
    String url,
    BoxFit fit,
    double? width,
    double? height,
    Widget? placeholder,
  ) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
    );
  }
}
