import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/Quiz.dart';
import '../../domain/repositories/QuizRepository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final String baseUrl;
  final http.Client cliente;

  QuizRepositoryImpl({required this.baseUrl, http.Client? client})
      : cliente = client ?? http.Client();

  @override
  Future<Quiz> save(Quiz quiz) async {
    // Consider as new if quizId is empty or if it looks like a local placeholder (e.g. startsWith 'quiz_')
    final isLikelyUuid = quiz.quizId.length == 36 && quiz.quizId.contains('-');
    final isNew = quiz.quizId.isEmpty || quiz.quizId.startsWith('quiz_') || !isLikelyUuid;
    final url = isNew ? '$baseUrl/kahoots' : '$baseUrl/kahoots/${quiz.quizId}';
    final method = isNew ? 'POST' : 'PUT';

    // Construir payload según el contrato del backend (mapea nombres y evita enviar IDs locales)
    final body = jsonEncode(_quizToApiPayload(quiz));

    // Debug logs: imprimir URL, método, headers y body para ayudar a reproducir errores 500 del servidor.
    try {
      print('QuizRepositoryImpl.save -> $method $url');
      print('Request headers: ${{'Content-Type': 'application/json'}}');
      print('Request body: $body');
    } catch (_) {}

    final uri = Uri.parse(url);
    http.Response response;
    try {
      if (method == 'POST') {
        response = await cliente.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      } else {
        response = await cliente.put(uri, headers: {'Content-Type': 'application/json'}, body: body);
      }
    } catch (e, st) {
      // Network or client error — print stacktrace so user can paste it here.
      print('QuizRepositoryImpl.save -> Exception performing HTTP $method: $e');
      print('Stacktrace: $st');
      rethrow;
    }

    // Imprimir respuesta para facilitar debugging remoto (status, headers, body)
    try {
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
    } catch (_) {}

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return Quiz.fromJson(Map<String, dynamic>.from(jsonResponse));
    } else {
      // Lanzar excepción con contexto amplio para que los logs en consola sean útiles
      final msg = 'Error al guardar el quiz: ${response.statusCode} - ${response.body}';
      print(msg);
      throw Exception(msg);
    }
  }

  /// Mapea la entidad interna [Quiz] al payload que espera el backend.
  Map<String, dynamic> _quizToApiPayload(Quiz quiz) {
    // Fallback authorId público para pruebas si el cliente todavía contiene el placeholder.
    const fallbackAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
    final String authorId = (quiz.authorId.isEmpty || quiz.authorId.contains('placeholder'))
      ? fallbackAuthorId
      : quiz.authorId;

    String _safeString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      return v.toString();
    }

    // Si el valor parece ser una ruta local o una URL en vez de un mediaId válido,
    // devolvemos null para evitar enviar datos inválidos al backend.
    String? _maybeMediaId(String? v) {
      if (v == null) return null;
      final s = v.trim();
      if (s.isEmpty) return null;
      // heurística: si contiene '/' o '\' o 'http' probablemente no es un id remoto
      if (s.contains('/') || s.contains('\\') || s.startsWith('http')) return null;
      // si es muy largo, probablemente sea una path en vez de un id
      if (s.length > 64) return null;
      return s;
    }

    return {
      'authorId': authorId,
      'title': _safeString(quiz.title),
      'description': _safeString(quiz.description),
      // El backend espera 'coverImageId' (id de recurso). Si no existe, enviar cadena vacía en lugar de null.
      'coverImageId': _maybeMediaId(quiz.coverImageUrl),
      'visibility': _safeString(quiz.visibility),
      // Usar los valores del quiz si existen, de lo contrario dejar valores por defecto
      'status': _safeString(quiz.status ?? 'draft'),
      'category': _safeString(quiz.category ?? 'Tecnología'),
      'themeId': _safeString(quiz.themeId),
      'questions': quiz.questions.map((q) {
        return {
          'questionText': _safeString(q.text),
          // backend espera mediaId (id de media). Si no existe o es una ruta local, enviar null.
          'mediaId': _maybeMediaId(q.mediaUrl),
          'questionType': _safeString(q.type),
          'timeLimit': q.timeLimit,
          'points': q.points,
          'answers': q.answers.map((a) {
            return {
              'answerText': _safeString(a.text),
              'mediaId': _maybeMediaId(a.mediaUrl),
              'isCorrect': a.isCorrect,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  @override 
  Future<Quiz?> find(String id) async {
    final response = await cliente.get(Uri.parse('$baseUrl/kahoots/$id'));
    if (response.statusCode == 200){
      final jsonResponse = jsonDecode(response.body);
      return Quiz.fromJson(jsonResponse);
    }else if (response.statusCode == 404){
      return null;
    }else {
      throw Exception('Error al buscar el quiz: ${response.statusCode}');
    }
  }

  @override
  Future<void> delete(String id) async {
    final response = await cliente.delete(Uri.parse('$baseUrl/kahoots/$id'));
    // backend may return 200 or 204
    if (response.statusCode != 204 && response.statusCode != 200){
      throw Exception('Error al eliminar el quiz: ${response.statusCode}');
    }
  }

  @override
  Future<List<Quiz>> searchByAuthor(String authorId) async {
    // backend exposes: GET /kahoots/user/:userId
    final response = await cliente.get(Uri.parse('$baseUrl/kahoots/user/$authorId'));

    if (response.statusCode == 200){
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((json) => Quiz.fromJson(Map<String, dynamic>.from(json as Map))).toList();
    }else {
      throw Exception('Error al buscar quizzes por autor: ${response.statusCode}');
    }
  }
}


