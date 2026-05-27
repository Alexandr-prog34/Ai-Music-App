import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> triggerTrackDownload(String url, {String? fileName}) async {
  if (Platform.isLinux) {
    // For Linux: download to Downloads directory
    try {
      final downloadDir = await _getLinuxDownloadDir();
      final finalFileName = fileName ?? 'track.mp3';
      final filepath = '$downloadDir/$finalFileName';
      
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final file = File(filepath);
        final sink = file.openWrite();
        await for (final chunk in response) {
          sink.add(chunk);
        }
        await sink.close();
        httpClient.close();
        // Success: file downloaded
        return;
      }
      httpClient.close();
      throw Exception('Failed to download: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
  throw UnsupportedError('Track download is only supported on Linux, Web, and Android.');
}

Future<String> _getLinuxDownloadDir() async {
  // Try to get user's Downloads folder
  final homeDir = Platform.environment['HOME'];
  if (homeDir != null) {
    final downloadsDir = Directory('$homeDir/Downloads');
    if (await downloadsDir.exists()) {
      return downloadsDir.path;
    }
  }
  // Fallback to temp directory
  final tempDir = await getTemporaryDirectory();
  return tempDir.path;
}
