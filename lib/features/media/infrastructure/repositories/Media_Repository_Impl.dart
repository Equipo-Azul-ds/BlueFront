import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:flutter/foundation.dart';
import '../../domain/entities/Media.dart';
import '../../domain/repositories/Media_Repository.dart';
import '../../../../injection.dart';
import '../../../../local/secure_storage.dart';

class MediaRepositoryImpl implements MediaRepository {
  final String baseUrl;
  final http.Client client;

  MediaRepositoryImpl({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  /// Sube los bytes de un archivo como multipart al endpoint `/media/upload`.
  /// Devuelve los metadatos Media creados por el servidor (o lanza una excepción si falla).
  Future<Media> uploadFromBytes(
    Uint8List fileBytes,
    String fileName,
    String mimeType, {
    String? bearerToken,
  }) async {
    final url = Uri.parse('$baseUrl/media/upload');

    final request = http.MultipartRequest('POST', url);
    // Asegura que mimeType tenga un valor por defecto si viene vacío
    final safeMime = (mimeType.trim().isEmpty)
        ? 'application/octet-stream'
        : mimeType.trim();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(safeMime),
      ),
    );

    // Recupera el token Bearer desde SecureStorage
    final token = await SecureStorage.instance.read('token');
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    } else {
      print('[ERROR] No valid Bearer token found in SecureStorage');
      throw Exception('Authentication token is missing');
    }

    // Información de depuración: cabeceras y metadatos del archivo (se imprimen justo antes del envío)
    try {
      print('MediaRepositoryImpl.uploadFromBytes -> POST $url');
      print('Multipart request headers: ${request.headers}');
      print(
        'Uploading file: filename=$fileName mime=$safeMime size=${fileBytes.length}',
      );
    } catch (_) {}

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e, st) {
      print(
        'MediaRepositoryImpl.uploadFromBytes -> Exception while sending multipart request: $e',
      );
      print('Stacktrace: $st');
      rethrow;
    }

    final response = await http.Response.fromStream(streamed);

    // Registra completamente la respuesta para facilitar la depuración
    try {
      print('Upload response status: ${response.statusCode}');
      print('Upload response headers: ${response.headers}');
      print('Upload response body: ${response.body}');
    } catch (_) {}

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final raw = jsonDecode(response.body);
        Map<String, dynamic> mediaJson;
        if (raw is Map<String, dynamic>) {
          // Algunas implementaciones devuelven { data: { ... } }
          if (raw['data'] is Map<String, dynamic>) {
            mediaJson = raw['data'] as Map<String, dynamic>;
          } else {
            mediaJson = raw;
          }
        } else {
          throw Exception('Formato inesperado en respuesta de upload');
        }

        final media = Media.fromJson(mediaJson);
        // Preferimos URL absoluta si está disponible para que el frontend pueda renderizar directamente
        if ((media.path).isEmpty && (mediaJson['url'] is String)) {
          final url = (mediaJson['url'] as String);
          return Media(
            id: media.id,
            path: url,
            mimeType: media.mimeType,
            size: media.size,
            originalName: media.originalName,
            createdAt: media.createdAt,
            previewPath: media.previewPath,
            ownerId: media.ownerId,
          );
        }

        return media;
      } catch (e, st) {
        print('Failed to parse Media JSON after successful upload: $e');
        print('Stacktrace: $st');
        throw Exception(
          'Upload succeeded but failed to parse Media JSON: $e - body: ${response.body}',
        );
      }
    } else {
      // Incluye el cuerpo de la respuesta para ayudar a depurar errores 500 del backend
      final msg =
          'Error uploading file: ${response.statusCode} ${response.body}';
      print(msg);
      throw Exception(msg);
    }
  }

  /// Persistir solo metadatos: actualmente el backend expone un endpoint de subida
  /// que ya persiste los metadatos y devuelve Media. Este método será un no-op
  /// y retornará el objeto media proporcionado para compatibilidad con flujos antiguos.
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

  /// Recupera los assets de categoría "theme" desde el backend.
  /// Devuelve un arreglo con los campos crudos de la respuesta, normalizando el contenedor `data` si existe.
  @override
  Future<List<Map<String, dynamic>>> fetchThemes() async {
    // Nuevo endpoint expuesto por el backend: GET /media/themes
    final url = Uri.parse('$baseUrl/media/themes');
    final response = await client.get(url);

    try {
      print(
        'MediaRepositoryImpl.fetchThemes -> GET $url status=${response.statusCode}',
      );
      print('fetchThemes response body: ${response.body}');
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        items = decoded['data'] as List;
      } else {
        throw Exception('Formato inesperado al obtener themes');
      }

      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception(
      'Error obteniendo themes: ${response.statusCode} ${response.body}',
    );
  }
}
