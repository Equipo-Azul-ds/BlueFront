import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/kahoot_model.dart';
import '../../domain/entities/kahoot_progress_model.dart';
import '../../domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final String baseUrl;
  final http.Client cliente;

  LibraryRepositoryImpl({required this.baseUrl, http.Client? client})
    : cliente = client ?? http.Client();

  // ---------------------------------------------------------
  // 1. OBTENER CREACIONES (Endpoint: /library/my-creations)
  // ---------------------------------------------------------
  @override
  Future<List<Kahoot>> getCreatedKahoots({required String userId}) async {
    final url = Uri.parse('$baseUrl/library/my-creations');
    // El Postman muestra que el GET lleva un body JSON con el userId
    final request = http.Request('GET', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'userId': userId});

    final streamedResponse = await cliente.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Kahoot.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener creaciones: ${response.statusCode}');
    }
  }

  // ---------------------------------------------------------
  // 2. OBTENER FAVORITOS (Endpoint: /library/favorites/)
  // ---------------------------------------------------------
  @override
  Future<List<Kahoot>> getFavoriteKahoots({required String userId}) async {
    final url = Uri.parse('$baseUrl/library/favorites/');

    final request = http.Request('GET', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'userId': userId});

    final streamedResponse = await cliente.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Kahoot.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener favoritos: ${response.statusCode}');
    }
  }

  // ---------------------------------------------------------
  // 3. TOGGLE FAVORITO (POST para añadir, DELETE para quitar)
  // ---------------------------------------------------------
  @override
  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required String userId,
    required bool isFavorite,
  }) async {
    // Si isFavorite es true, significa que queremos marcarlo (POST)
    // Si es false, significa que queremos quitarlo (DELETE)
    final method = isFavorite ? 'POST' : 'DELETE';
    final url = Uri.parse('$baseUrl/library/favorites/$kahootId');

    final request = http.Request(method, url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'userId': userId});

    final response = await cliente.send(request);

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception('Error al cambiar favorito: ${response.statusCode}');
    }
  }

  // ---------------------------------------------------------
  // MÉTODOS PENDIENTES (Aún no están en Postman)
  // ---------------------------------------------------------
  @override
  Future<List<Kahoot>> getInProgressKahoots({required String userId}) async {
    // Por ahora devolvemos lista vacía hasta que el backend confirme el endpoint
    return [];
  }

  @override
  Future<List<Kahoot>> getCompletedKahoots({required String userId}) async {
    return [];
  }

  @override
  Future<KahootProgress?> getProgressForKahoot({
    required String kahootId,
    required String userId,
  }) async {
    return null;
  }

  @override
  Future<Kahoot> getKahootById(String id) async {
    // Podrías usar el endpoint de tu compañero si es el mismo: $baseUrl/kahoots/$id
    throw UnimplementedError();
  }

  @override
  Future<void> updateProgress({
    required String kahootId,
    required String userId,
    required double newPercentage,
    required bool isCompleted,
  }) async {
    // Pendiente de endpoint
  }
}
