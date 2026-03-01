import 'package:dio/dio.dart';

import '../../shared/domain/track.dart';

class TracksApi {
  final Dio dio;

  TracksApi(this.dio);

  //GET /tracks
  Future<List<Track>> listTracks({
    bool? favorite,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      "/tracks",
      queryParameters: {
        if (favorite != null) "favorite": favorite,
        "limit": limit,
        "offset": offset,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException("Empty tracks response");
    }

    final map = data as Map<String, dynamic>;

    final items = (map["items"] as List?) ?? [];

    return items
        .map(
          (json) => Track.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  //GET /tracks/{id}
  Future<Track> getTrack(String id) async {
    final response = await dio.get("/tracks/$id");

    final data = response.data;

    if (data == null) {
      throw const FormatException("Empty track response");
    }

    return Track.fromJson(
      data as Map<String, dynamic>,
    );
  }

  //DELETE /tracks/{id}
  Future<void> deleteTrack(String id) async {
    await dio.delete("/tracks/$id");
  }

  //PUT /tracks/{id}/favorite
  Future<void> addFavorite(String id) async {
    await dio.put("/tracks/$id/favorite");
  }

  //DELETE /tracks/{id}/favorite
  Future<void> removeFavorite(String id) async {
    await dio.delete("/tracks/$id/favorite");
  }

  //GET /tracks/{id}/download
  //backend returns redirect (302)
  Future<String> getDownloadUrl(String id) async {
    final response = await dio.get(
      "/tracks/$id/download",
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          return status != null && status < 400;
        },
      ),
    );

    final location =
        response.headers.value("location");

    if (location == null) {
      throw const FormatException(
        "Download URL missing",
      );
    }

    return location;
  }
}