import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/Quiz.dart';
import '../../domain/repositories/QuizRepository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final String baseUrl;
  final http.Client cliente;
  String? _currentUserId;

  QuizRepositoryImpl({required this.baseUrl, http.Client? client})
      : cliente = client ?? http.Client() {
    try {
      print('QuizRepositoryImpl initialized with baseUrl=$baseUrl');
    } catch (_) {}
  }

  // Traduce los tipos usados en el cliente a los que espera el backend.
  String _mapQuestionType(String raw) {
    final t = raw.trim().toLowerCase();
    if (t == 'quiz' || t == 'single') return 'single';
    if (t == 'multiple') return 'multiple';
    if (t == 'true_false' || t == 'true-false' || t == 'truefalse') return 'true_false';
    return raw; // deja pasar valores inesperados para que el backend falle explícitamente
  }

  // Valida formato UUID v4 simple.
  bool _isUuidV4(String s) {
    final re = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    return re.hasMatch(s.trim());
  }

  // Limpia prefijos locales (q_/a_) para que el backend reciba solo UUIDs.
  String _sanitizeId(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.startsWith('q_') || trimmed.startsWith('a_')) {
      return trimmed.substring(2);
    }
    return trimmed;
  }

  // Construye headers según contrato: Content-Type y x-debug-user-id.
  Map<String, String> _headers({required String userId, bool json = false}) {
    final id = userId.trim();
    final h = <String, String>{
      'Accept': 'application/json',
    };
    if (json) h['Content-Type'] = 'application/json';
    if (id.isNotEmpty) {
      h['x-debug-user-id'] = id;
    }
    return h;
  }

  // Imprime cadenas largas en bloques para evitar truncado en logcat/terminal.
  void _logLarge(String label, String content, {int chunkSize = 800}) {
    try {
      final total = content.length;
      if (total == 0) {
        print('$label [empty]');
        return;
      }
      for (int i = 0; i < total; i += chunkSize) {
        final end = (i + chunkSize < total) ? i + chunkSize : total;
        print('$label [$i-$end]: ${content.substring(i, end)}');
      }
      print('$label length=$total');
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
    _currentUserId = quiz.authorId.trim();

    final payload = _quizToApiPayload(
      quiz,
      includeIds: !isNew,
      allowEmptyAnswers: !isNew,
    );
    final body = jsonEncode(payload);
    final prettyBody = const JsonEncoder.withIndent('  ').convert(payload);
    // Headers: enviar el userId del currentUser (incluye variantes por compatibilidad)
    if (!_isUuidV4(quiz.authorId)) {
      print('QuizRepositoryImpl.save -> authorId no parece UUID v4: "${quiz.authorId}"');
    }
    final headers = _headers(userId: _currentUserId ?? quiz.authorId, json: true);

    // Debug logs: imprimir URL, método, headers y body para ayudar a reproducir errores 500 del servidor.
    try {
      print('QuizRepositoryImpl.save -> $method $url');
      print('Request headers: $headers');
      _logLarge('Request body (pretty)', prettyBody);
      _logLarge('Request body (raw)', body);
    } catch (_) {}

    final uri = Uri.parse(url);
    http.Response response;
    try {
      if (method == 'POST') {
        response = await cliente.post(uri, headers: headers, body: body);
      } else {
        response = await cliente.put(uri, headers: headers, body: body);
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
      _logLarge('Response body', response.body);
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
  Map<String, dynamic> _quizToApiPayload(
    Quiz quiz, {
    bool includeIds = false,
    bool allowEmptyAnswers = false,
  }) {
    // Fallback authorId público para pruebas si el cliente todavía contiene el placeholder.
    const fallbackAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
    final String authorId = quiz.authorId.trim();
    if (authorId.isEmpty) {
      throw Exception('authorId vacío: debe ser el userId del currentUser logeado');
    }

    String _safeString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      return v.toString();
    }

    // Acepta UUID o URL; el backend usa 'mediaId' pero almacenaremos el URL cuando sea disponible.
    String? _mediaIdAllowingUrl(String? v) {
      if (v == null) return null;
      final s = v.trim();
      if (s.isEmpty) return null;
      return s; // no restringir a UUID, permitir URL
    }

    // Normaliza a los valores que el backend muestra en el contrato: "Public" / "Private".
    final visRaw = _safeString(quiz.visibility).trim();
    final vis = visRaw.isEmpty
      ? 'Private'
      : (visRaw.toLowerCase() == 'public'
        ? 'Public'
        : (visRaw.toLowerCase() == 'private' ? 'Private' : visRaw));

    // Normaliza status al formato esperado: Draft/Publish
    String _normalizeStatus(String? raw, {required bool isUpdate}) {
      final v = (raw ?? '').trim().toLowerCase();
      if (v == 'publish' || v == 'published') return 'Publish';
      if (v == 'draft') return 'Draft';
      return isUpdate ? 'Draft' : 'Publish';
    }

    final statusValue = _normalizeStatus(quiz.status, isUpdate: allowEmptyAnswers);

    void _assertQuestionValid(String text, List<Map<String, dynamic>> answers) {
      final qText = text.trim();
      if (qText.isEmpty) {
        throw Exception('La pregunta necesita enunciado.');
      }
      if (!allowEmptyAnswers && answers.isEmpty) {
        throw Exception('Cada pregunta necesita respuestas.');
      }
    }

    void _assertAnswerValid(String text, String? mediaId) {
      final aText = text.trim();
      final hasText = aText.isNotEmpty;
      final hasMedia = mediaId != null && mediaId.trim().isNotEmpty;
      if (!hasText && !hasMedia) {
        throw Exception('Cada respuesta debe tener texto o media.');
      }
      if (hasText && hasMedia) {
        throw Exception('La respuesta no puede tener texto y media a la vez.');
      }
    }

    // themeId no puede ir vacío; enviamos siempre el valor seleccionado (UUID o URL) como string.
    final rawTheme = _safeString(quiz.themeId);
    final safeThemeId = rawTheme.isNotEmpty ? rawTheme : null;

    final payload = <String, dynamic>{
      'title': _safeString(quiz.title),
      'description': _safeString(quiz.description),
        // Enviar URL en coverImageId según contrato
        'coverImageId': _safeString(quiz.coverImageUrl).trim().isNotEmpty
          ? _safeString(quiz.coverImageUrl).trim()
          : null,
      'visibility': vis,
      // Usar los valores del quiz si existen, de lo contrario dejar valores por defecto
      'status': statusValue,
      'category': _safeString(quiz.category ?? 'Tecnología'),
      'themeId': safeThemeId,
      'questions': quiz.questions.asMap().entries.map((entry) {
        final idx = entry.key;
        final q = entry.value;
        final answersList = q.answers.map((a) {
          final mediaId = _mediaIdAllowingUrl(a.mediaUrl);
          final textRaw = _safeString(a.text).trim();
          final text = textRaw.isEmpty ? null : textRaw;
          _assertAnswerValid(text ?? '', mediaId);
          final answerMap = <String, dynamic>{
            'text': text,
            // Guardar URL en mediaId según contrato
            'mediaId': _safeString(a.mediaUrl).trim().isNotEmpty
                ? _safeString(a.mediaUrl).trim()
                : null,
            'isCorrect': a.isCorrect,
          };
          if (includeIds) answerMap['id'] = _sanitizeId(a.answerId);
          return answerMap;
        }).toList();

        final qText = _safeString(q.text);
        if (!(allowEmptyAnswers && answersList.isEmpty)) {
          _assertQuestionValid(qText, answersList);
        }

        final questionMap = <String, dynamic>{
          'text': qText.trim(),
          // Guardar URL en mediaId según contrato
          'mediaId': _safeString(q.mediaUrl).trim().isNotEmpty
              ? _safeString(q.mediaUrl).trim()
              : null,
          'type': _mapQuestionType(_safeString(q.type)),
          'timeLimit': q.timeLimit,
          'points': q.points,
          'position': idx,
          'answers': answersList.isEmpty && allowEmptyAnswers ? null : answersList,
        };

        if (includeIds) {
          questionMap['id'] = _sanitizeId(q.questionId);
        }

        return questionMap;
      }).toList(),
    };

    payload['authorId'] = authorId;

    if (includeIds) {
      // Algunos backends solo esperan id en la ruta; se omite aquí para evitar 400.
      // Si llegara a ser requerido, se puede reactivar.
      // payload['id'] = quiz.quizId;
    }

    return payload;
  }

  @override 
  Future<Quiz?> find(String id) async {
    final url = '$baseUrl/kahoots/$id';
    final headers = _headers(userId: _currentUserId ?? '', json: false);
    try {
      print('QuizRepositoryImpl.find -> GET $url');
      print('Request headers: $headers');
    } catch (_) {}
    final response = await cliente.get(Uri.parse(url), headers: headers);
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
  Future<void> delete(String id, String userId) async {
    if (id.trim().isEmpty) {
      print('QuizRepositoryImpl.delete -> Ignoring delete request with empty id');
      return;
    }

    _currentUserId = userId.trim();
    if ((_currentUserId ?? '').isEmpty) {
      throw Exception('delete requiere userId para enviar x-debug-user-id');
    }

    final url = '$baseUrl/kahoots/$id';
    final headers = _headers(userId: _currentUserId ?? '', json: false);
    try {
      print('QuizRepositoryImpl.delete -> DELETE $url');
      print('Request headers: $headers');
      final response = await cliente.delete(Uri.parse(url), headers: headers);
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
    _currentUserId = authorId.trim();
    final headers = _headers(userId: authorId, json: false);
    try {
      print('QuizRepositoryImpl.searchByAuthor -> GET $url');
      print('Request headers: $headers');
    } catch (_) {}
    final response = await cliente.get(Uri.parse(url), headers: headers);

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


