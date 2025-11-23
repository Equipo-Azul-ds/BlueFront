import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:flutter/foundation.dart';
import '../../domain/entities/Media.dart';
import '../../domain/repositories/Media_Repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final String baseUrl;
  final http.Client client;

  MediaRepositoryImpl({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  /// Uploads file bytes as multipart to backend `/media/upload`.
  /// Returns the created Media metadata from server.
  Future<Media> uploadFromBytes(Uint8List fileBytes, String fileName, String mimeType) async {
    final url = Uri.parse('$baseUrl/media/upload');

    final request = http.MultipartRequest('POST', url);
    // Ensure mimeType has a fallback
    final safeMime = (mimeType.trim().isEmpty) ? 'application/octet-stream' : mimeType.trim();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(safeMime),
      ),
    );

    // Debug info: headers and file info
    try {
      print('MediaRepositoryImpl.uploadFromBytes -> POST $url');
      print('Multipart request headers: ${request.headers}');
      print('Uploading file: filename=$fileName mime=$safeMime size=${fileBytes.length}');
    } catch (_) {}

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e, st) {
      print('MediaRepositoryImpl.uploadFromBytes -> Exception while sending multipart request: $e');
      print('Stacktrace: $st');
      rethrow;
    }

    final response = await http.Response.fromStream(streamed);

    // Log response fully for easier debugging
    try {
      print('Upload response status: ${response.statusCode}');
      print('Upload response headers: ${response.headers}');
      print('Upload response body: ${response.body}');
    } catch (_) {}

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final jsonMap = jsonDecode(response.body);
        // Some backends return an object with { id: '...', data: { type: 'Buffer', data: [...] } }
        // In that case we only need the returned id (the media record) so we can
        // associate it to quizzes/questions/answers. Build a minimal Media object
        // with the id and use the repository's `baseUrl/media/:id` as the fetch path.
        if (jsonMap is Map<String, dynamic> && jsonMap.containsKey('id') && jsonMap.containsKey('data')) {
          final id = (jsonMap['id'] ?? '').toString();
          return Media(
            id: id,
            path: id, // store id here; UI/other repos should treat this as mediaId
            mimeType: safeMime,
            size: fileBytes.length,
            originalName: fileName,
            createdAt: DateTime.now(),
            previewPath: null,
            ownerId: null,
          );
        }

        // Otherwise try to map full metadata response to Media
        return Media.fromJson(Map<String, dynamic>.from(jsonMap as Map));
      } catch (e, st) {
        print('Failed to parse Media JSON after successful upload: $e');
        print('Stacktrace: $st');
        // If parsing fails, still return a minimal Media object using the safeMime and file info
        try {
          // Attempt to extract id if possible
          final fallbackJson = jsonDecode(response.body);
          final maybeId = (fallbackJson is Map && fallbackJson.containsKey('id')) ? fallbackJson['id'].toString() : '';
          if (maybeId.isNotEmpty) {
            return Media(
              id: maybeId,
              path: maybeId,
              mimeType: safeMime,
              size: fileBytes.length,
              originalName: fileName,
              createdAt: DateTime.now(),
            );
          }
        } catch (_) {}

        throw Exception('Upload succeeded but failed to parse Media JSON: $e - body: ${response.body}');
      }
    } else {
      // Include body to help debugging backend 500s
      final msg = 'Error uploading file: ${response.statusCode} ${response.body}';
      print(msg);
      throw Exception(msg);
    }
  }

  /// Persist metadata-only: currently backend exposes upload endpoint which
  /// already persists metadata and returns Media. This method will be a no-op
  /// and return the provided media for compatibility with older flows.
  Future<Media> save(Media media) async {
    // If you have an endpoint to save metadata separately, implement it here.
    // For now, just return the passed media.
    return media;
  }

  Future<Media?> findById(String id) async {
    final response = await client.get(Uri.parse('$baseUrl/media/$id'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Media.fromJson(json);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Error buscando media: ${response.statusCode}');
    }
  }

  Future<void> delete(String id) async {
    final response = await client.delete(Uri.parse('$baseUrl/media/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error eliminando media: ${response.statusCode}');
    }
  }
}