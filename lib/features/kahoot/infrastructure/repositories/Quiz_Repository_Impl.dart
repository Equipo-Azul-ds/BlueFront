import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/Quiz.dart';
import '../../domain/repositories/QuizRepository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final String baseUrl;
  final http.Client cliente;

  QuizRepositoryImpl({required this.baseUrl, http.Client? client})
      : cliente = client ?? http.Client() {
    try {
      print('QuizRepositoryImpl initialized with baseUrl=$baseUrl');
    } catch (_) {}
  }

  @override
  Future<Quiz> save(Quiz quiz) async {
    // Determino si es nuevo o actualización basándose solo en que quiz.quizId esté vacío.
    // Considero que quiz es un objeto nuevo solo si quiz.quizId está vacío. Evito validar UUIDs o
      // inventar identificadores locales en la capa del repositorio; que sea el servidor quien decida.
      final isNew = quiz.quizId.isEmpty;
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
      // Error de red o de cliente: imprimir el seguimiento de la pila para que el usuario pueda pegarlo aquí.
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

    // También persiste un archivo de depuración con la solicitud y la respuesta
    // para ayudar cuando `flutter logs` no esté disponible.
    try {
      final debugSb = StringBuffer();
      debugSb.writeln('==== QuizRepositoryImpl DEBUG ====');
      debugSb.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
      debugSb.writeln('Request:');
      debugSb.writeln(body);
      debugSb.writeln('--- Response ---');
      debugSb.writeln('Status: ${response.statusCode}');
      debugSb.writeln('Headers: ${response.headers}');
      debugSb.writeln('Body: ${response.body}');

      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}debug_quiz_http.log');
        await file.writeAsString(debugSb.toString(), mode: FileMode.append, flush: true);
        print('QuizRepositoryImpl -> Wrote debug_quiz_http.log to ${file.path}');
      } catch (fe) {
        print('QuizRepositoryImpl -> Failed writing debug file: $fe');
      }
    } catch (_) {}

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      if (body.trim().isNotEmpty) {
        final jsonResponse = jsonDecode(body);
        return Quiz.fromJson(Map<String, dynamic>.from(jsonResponse));
      }

      // Fallback: si no hay cuerpo pero hay un encabezado Location, intenta obtener el
      // recurso creado desde esa ubicación para que los llamadores reciban un `Quiz` completo.
      final locationHeader = response.headers['location'] ?? response.headers['Location'];
      if (locationHeader != null && locationHeader.trim().isNotEmpty) {
        try {
          final uri = Uri.parse(locationHeader);
          final segments = uri.pathSegments;
          if (segments.isNotEmpty) {
            final createdId = segments.last;
            final fetched = await find(createdId);
            if (fetched != null) return fetched;
          }
        } catch (_) {
            // ignoro errores de análisis/recuperación y continuar con la excepción a continuación
        }
      }

      throw Exception('Respuesta inválida del servidor: cuerpo vacío y sin Location');
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

    // Normalize visibility: backend expects either 'public' or 'private'.
    var vis = _safeString(quiz.visibility).toLowerCase().trim();
    if (vis != 'public' && vis != 'private') vis = 'private';

    return {
      'authorId': authorId,
      'title': _safeString(quiz.title),
      'description': _safeString(quiz.description),
      // El backend espera 'coverImageId' (id de recurso). Si no existe, enviar cadena vacía en lugar de null.
      'coverImageId': _maybeMediaId(quiz.coverImageUrl) ?? '',
      'visibility': vis,
      // Usar los valores del quiz si existen, de lo contrario dejar valores por defecto
      'status': _safeString(quiz.status ?? 'draft'),
      'category': _safeString(quiz.category ?? 'Tecnología'),
      'themeId': _safeString(quiz.themeId),
      'questions': quiz.questions.map((q) {
        return {
          'questionText': _safeString(q.text),
          // backend espera mediaId (id de media). Si no existe o es una ruta local, enviar cadena vacía.
          'mediaId': _maybeMediaId(q.mediaUrl) ?? '',
          'questionType': _safeString(q.type),
          'timeLimit': q.timeLimit,
          'points': q.points,
          'answers': q.answers.map((a) {
            return {
              'answerText': _safeString(a.text),
              'mediaId': _maybeMediaId(a.mediaUrl) ?? '',
              'isCorrect': a.isCorrect,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  @override 
  Future<Quiz?> find(String id) async {
    final url = '$baseUrl/kahoots/$id';
    try { print('QuizRepositoryImpl.find -> GET $url'); } catch (_) {}
    final response = await cliente.get(Uri.parse(url));
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
    if (id.trim().isEmpty) {
      print('QuizRepositoryImpl.delete -> Ignoring delete request with empty id');
      return;
    }

    final url = '$baseUrl/kahoots/$id';
    try {
      print('QuizRepositoryImpl.delete -> DELETE $url');
      final response = await cliente.delete(Uri.parse(url));
      print('QuizRepositoryImpl.delete -> Response status: ${response.statusCode} body: ${response.body}');
      // El backend puede devolver 200 o 204
      if (response.statusCode != 204 && response.statusCode != 200){
        throw Exception('Error al eliminar el quiz: ${response.statusCode} - ${response.body}');
      }
    } catch (e, st) {
      print('QuizRepositoryImpl.delete -> Exception performing DELETE: $e');
      print(st);
      rethrow;
    }
  }

  @override
  Future<List<Quiz>> searchByAuthor(String authorId) async {
    // El backend expone: GET /kahoots/user/:userId
    // Devuelve un array JSON con los kahoots del autor (200 -> lista de quizzes).
    // Los errores 5xx se tratan como transitorios y devuelven lista vacía; los 4xx se propagan.
    final url = '$baseUrl/kahoots/user/$authorId';
    try { print('QuizRepositoryImpl.searchByAuthor -> GET $url'); } catch (_) {}
    final response = await cliente.get(Uri.parse(url));

    try { print('QuizRepositoryImpl.searchByAuthor -> Response status: ${response.statusCode}'); } catch (_) {}

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      try { print('QuizRepositoryImpl.searchByAuthor -> Fetched ${jsonResponse.length} quizzes'); } catch (_) {}
      return jsonResponse.map((json) => Quiz.fromJson(Map<String, dynamic>.from(json as Map))).toList();
    } else {
      final msg = 'Error al buscar quizzes por autor: ${response.statusCode} - ${response.body}';
      try { print('QuizRepositoryImpl.searchByAuthor -> $msg'); } catch (_) {}

      // Si el servidor devolvió un 5xx, lo trato como un error transitorio del backend
      // y devuelvo una lista vacía para que la UI pueda seguir funcionando con
      // posibles elementos en caché local. Para errores 4xx propagamos la excepción
      // para que los llamadores puedan mostrar problemas de autenticación/validación.
      if (response.statusCode >= 500 && response.statusCode < 600) {
        try { print('QuizRepositoryImpl.searchByAuthor -> Backend 5xx detected, returning empty list as fallback'); } catch (_) {}
        return <Quiz>[];
      }

      throw Exception(msg);
    }
  }
}


