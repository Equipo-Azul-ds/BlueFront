import 'dart:convert';
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
    final isNew = quiz.quizId.isEmpty;
    final url = isNew ? '$baseUrl/quizzes' : '$baseUrl/quizzes/${quiz.quizId}';
    final method = isNew ? 'POST' : 'PUT';

    final body = jsonEncode(quiz.toJson());

    final response = (method == 'POST')
        ? await cliente.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body)
        : await cliente.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return Quiz.fromJson(Map<String, dynamic>.from(jsonResponse));
    } else {
      throw Exception('Error al guardar el quiz: ${response.statusCode} - ${response.body}');
    }
  }

  @override 
  Future<Quiz?> find(String id) async {
  final response = await cliente.get(Uri.parse('$baseUrl/quizzes/$id'));
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
    final response = await cliente.delete(Uri.parse('$baseUrl/quizzes/$id'));
    if (response.statusCode != 204){
      throw Exception('Error al eliminar el quiz: ${response.statusCode}');
    }
  }

  @override
  Future<List<Quiz>> searchByAuthor(String authorId) async {
    final response = await cliente.get(Uri.parse('$baseUrl/quizzes?authorId=$authorId'));

    if (response.statusCode == 200){
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((json) => Quiz.fromJson(Map<String, dynamic>.from(json as Map))).toList();
    }else {
      throw Exception('Error al buscar quizzes por autor: ${response.statusCode}');
    }
  }
}

