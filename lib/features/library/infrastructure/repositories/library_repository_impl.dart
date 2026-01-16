import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../local/secure_storage.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final String baseUrl;
  final http.Client client;

  LibraryRepositoryImpl({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  Future<List<Kahoot>> _fetchKahoots(String path, String userId) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await SecureStorage.instance.read('token');

    final request = http.Request('GET', url)
      ..headers['Content-Type'] = 'application/json';

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Aunque no es estándar enviar body en GET, se mantiene por compatibilidad si el backend lo requiere,
    // pero la autenticación principal ahora va por Header.
    request.body = jsonEncode({'userId': userId});

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final dynamic decodedData = jsonDecode(response.body);

      // Si el backend envuelve la lista en una llave "data" (como en tu log)
      if (decodedData is Map<String, dynamic> &&
          decodedData.containsKey('data')) {
        final List<dynamic> dataList = decodedData['data'] ?? [];
        return dataList
            .map((item) => Kahoot.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Si el backend devuelve la lista directamente
      if (decodedData is List) {
        return decodedData
            .map((item) => Kahoot.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Error (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<List<Kahoot>> getCreatedKahoots({required String userId}) async {
    // Alineado con Postman: /library/my-creations
    return _fetchKahoots(
      '/library/my-creations?orderBy=title&order=desc',
      userId,
    );
  }

  @override
  Future<List<Kahoot>> getFavoriteKahoots({required String userId}) async {
    // Alineado con Postman: /library/favorites/
    return _fetchKahoots(
      '/library/favorites/?page=1&limit=20&orderBy=title&order=asc',
      userId,
    );
  }

  @override
  Future<List<Kahoot>> getInProgressKahoots({required String userId}) async {
    // CORRECCIÓN según Postman: /library/in-progress
    return _fetchKahoots('/library/in-progress', userId);
  }

  @override
  Future<List<Kahoot>> getCompletedKahoots({required String userId}) async {
    // Alineado con Postman: /library/completed
    return _fetchKahoots('/library/completed', userId);
  }

  @override
  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required String userId,
    required bool isFavorite,
  }) async {
    final url = Uri.parse('$baseUrl/library/favorites/$kahootId');
    final method = isFavorite ? 'DELETE' : 'POST';
    final token = await SecureStorage.instance.read('token');

    final request = http.Request(method, url)
      ..headers['Content-Type'] = 'application/json';
      
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.body = jsonEncode({'userId': userId});

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      print(
        'Error Backend Favoritos: ${response.statusCode} - ${response.body}',
      );
      throw Exception('Error al actualizar favorito');
    }
  }

  @override
  Future<Kahoot> getKahootById(String id, {String? userId}) async {
    final url = Uri.parse('$baseUrl/kahoots/$id');

    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'x-debug-user-id': userId ?? '', // REMOVE
      },
    );

    if (response.statusCode == 200) {
      final dynamic decodedData = jsonDecode(response.body);

      // Verificamos si los datos vienen envueltos en la llave "data"
      if (decodedData is Map<String, dynamic> &&
          decodedData.containsKey('data')) {
        return Kahoot.fromJson(decodedData['data']);
      }
      return Kahoot.fromJson(decodedData as Map<String, dynamic>);
    } else {
      print('Error en Detalle (${response.statusCode}): ${response.body}');
      throw Exception('Error al obtener detalle del Kahoot');
    }
  }
}
