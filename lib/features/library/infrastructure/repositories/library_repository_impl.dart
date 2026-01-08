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

  // Helper para centralizar las peticiones GET con Body (requerido por tu backend)
  Future<http.Response> _sendGetWithBody(Uri url, String userId) async {
    final request = http.Request('GET', url);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    request.body = jsonEncode({'userId': userId});

    final streamedResponse = await cliente.send(request);
    return await http.Response.fromStream(streamedResponse);
  }

  @override
  Future<List<Kahoot>> getCreatedKahoots({required String userId}) async {
    final url = Uri.parse('$baseUrl/library/my-creations');
    final response = await _sendGetWithBody(url, userId);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Kahoot.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener creaciones: ${response.statusCode}');
    }
  }

  @override
  Future<List<Kahoot>> getFavoriteKahoots({required String userId}) async {
    final url = Uri.parse('$baseUrl/library/favorites/');
    final response = await _sendGetWithBody(url, userId);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Kahoot.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener favoritos: ${response.statusCode}');
    }
  }

  @override
  Future<List<Kahoot>> getInProgressKahoots({required String userId}) async {
    final url = Uri.parse('$baseUrl/library/in-progress');
    final response = await _sendGetWithBody(url, userId);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Kahoot.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener en progreso: ${response.statusCode}');
    }
  }

  @override
  Future<List<Kahoot>> getCompletedKahoots({required String userId}) async {
    final url = Uri.parse('$baseUrl/library/completed');
    final response = await _sendGetWithBody(url, userId);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Kahoot.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener completados: ${response.statusCode}');
    }
  }

  @override
  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required String userId,
    required bool isFavorite,
  }) async {
    final method = isFavorite ? 'POST' : 'DELETE';
    final url = Uri.parse('$baseUrl/library/favorites/$kahootId');

    final request = http.Request(method, url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'userId': userId});

    final response = await cliente.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al cambiar favorito: ${response.statusCode}');
    }
  }

  // Métodos que no están en la colección pero se mantienen por interfaz
  @override
  Future<KahootProgress?> getProgressForKahoot({
    required String kahootId,
    required String userId,
  }) async => null;

  @override
  Future<Kahoot> getKahootById(String id) async => throw UnimplementedError();

  @override
  Future<void> updateProgress({
    required String kahootId,
    required String userId,
    required double newPercentage,
    required bool isCompleted,
  }) async {}
}
