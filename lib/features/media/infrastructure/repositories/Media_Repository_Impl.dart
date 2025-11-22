import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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

    final request = http.MultipartRequest('POST', url)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: http.MediaType.parse(mimeType),
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonMap = jsonDecode(response.body);
      return Media.fromJson(jsonMap);
    } else {
      throw Exception('Error uploading file: ${response.statusCode} ${response.body}');
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