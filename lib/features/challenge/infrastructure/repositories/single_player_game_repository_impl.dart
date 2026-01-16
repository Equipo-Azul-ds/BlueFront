import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/single_player_game.dart';
import '../../application/dtos/single_player_dtos.dart';
import '../../domain/repositories/single_player_game_repository.dart';

/// HTTP-backed implementation that proxies all single player attempt
/// operations to the backend described in `API_ENDPOINTS.txt`.
class SinglePlayerGameRepositoryImpl implements SinglePlayerGameRepository {
  final String baseUrl;
  final http.Client httpClient;
  final FutureOr<String?> Function()? tokenProvider;

  SinglePlayerGameRepositoryImpl({
    required this.baseUrl,
    http.Client? client,
    this.tokenProvider,
  }) : httpClient = client ?? http.Client();

  void _logRequest(
    String method,
    Uri uri,
    Map<String, String> headers, {
    Object? body,
  }) {
    print('[SinglePlayer] REQUEST $method $uri');
    print('headers=${_maskHeaders(headers)}');
    if (body != null) {
      print('body=$body');
    }
  }

  void _logResponse(http.Response response) {
    final req = response.request;
    print('[SinglePlayer] RESPONSE ${req?.method ?? 'UNKNOWN'} ${req?.url ?? ''}');
    print('status=${response.statusCode}');
    print('body=${response.body}');
  }

  Map<String, String> _maskHeaders(Map<String, String> headers) {
    final masked = Map<String, String>.from(headers);
    final token = masked['Authorization'];
    if (token != null && token.isNotEmpty) {
      masked['Authorization'] = _maskToken(token);
    }
    return masked;
  }

  String _maskToken(String token) {
    if (token.length <= 8) {
      return '***';
    }
    final tail = token.substring(token.length - 4);
    return '***$tail';
  }

  Future<Map<String, String>> _buildJsonHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = await _resolveAuthToken();
    if (token != null && token.isNotEmpty) {
      final authValue = RegExp(r'^bearer ', caseSensitive: false).hasMatch(token)
          ? token
          : 'Bearer $token';
      headers['Authorization'] = authValue;
    }

    return headers;
  }

  Future<String?> _resolveAuthToken() async {
    try {
      final provider = tokenProvider;
      if (provider != null) {
        final value = await Future.value(provider());
        final trimmed = value?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    } catch (e) {
      print('SinglePlayerGameRepositoryImpl -> tokenProvider failed: $e');
    }
    return null;
  }

  @override
  Future<StartAttemptRepositoryResponse> startAttempt({
    required String kahootId,
  }) async {
    final uri = Uri.parse('$baseUrl/attempts');
    final payload = {
      'kahootId': kahootId,
    };

    http.Response response;
    final headers = await _buildJsonHeaders();
    try {
      print('SinglePlayerGameRepositoryImpl.startAttempt -> POST $uri');
      _logRequest('POST', uri, headers, body: payload);
      response = await httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );
      _logResponse(response);
    } catch (e, st) {
      print('SinglePlayerGameRepositoryImpl.startAttempt -> exception: $e');
      print(st);
      rethrow;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = _decodeBody(response.body);
      final game = _extractGameFromPayload(
        decoded,
        fallbackKahootId: kahootId,
      );
      final slide = _parseSlide(
        decoded['firstSlide'] ?? decoded['nextSlide'] ?? decoded['slide'],
      );
      return StartAttemptRepositoryResponse(game: game, nextSlide: slide);
    }

    throw Exception(
      'Failed to start attempt: ${response.statusCode} - ${response.body}',
    );
  }

  @override
  Future<AttemptStateRepositoryResponse> getAttemptState(String attemptId) async {
    final uri = Uri.parse('$baseUrl/attempts/$attemptId');
    http.Response response;
    final headers = await _buildJsonHeaders();
    try {
      print('SinglePlayerGameRepositoryImpl.getAttemptState -> GET $uri');
      _logRequest('GET', uri, headers);
      response = await httpClient.get(uri, headers: headers);
      _logResponse(response);
    } catch (e, st) {
      print('SinglePlayerGameRepositoryImpl.getAttemptState -> exception: $e');
      print(st);
      rethrow;
    }

    if (response.statusCode == 404) {
      return AttemptStateRepositoryResponse(game: null);
    }

    if (response.statusCode == 200) {
      final decoded = _decodeBody(response.body);
      final game = _tryExtractGame(
            decoded['attemptState'] ?? decoded['game'],
            fallbackAttemptId: attemptId,
          ) ??
          _extractGameFromPayload(
            decoded,
            fallbackAttemptId: attemptId,
          );
      final slide = _parseSlide(decoded['nextSlide']);
      final correctIndex = _extractCorrectAnswerIndex(decoded);
      return AttemptStateRepositoryResponse(
        game: game,
        nextSlide: slide,
        correctAnswerIndex: correctIndex,
      );
    }

    throw Exception(
      'Failed to fetch attempt $attemptId: ${response.statusCode} - ${response.body}',
    );
  }

  @override
  Future<SubmitAnswerRepositoryResponse> submitAnswer(
    String attemptId,
    PlayerAnswer playerAnswer,
  ) async {
    final uri = Uri.parse('$baseUrl/attempts/$attemptId/answer');
    final selectedIndexes = playerAnswer.answerIndex ?? <int>[];
    final slideId = playerAnswer.slideId;
    if (slideId == null || slideId.isEmpty) {
      throw ArgumentError('submitAnswer requires a valid slideId per API spec.');
    }
    final payload = <String, dynamic>{
      'slideId': slideId,
      'answerIndex': List<int>.from(selectedIndexes),
      'timeElapsedSeconds': (playerAnswer.timeUsedMs / 1000).round(),
    };

    http.Response response;
    final headers = await _buildJsonHeaders();
    try {
      print('SinglePlayerGameRepositoryImpl.submitAnswer -> POST $uri');
      _logRequest('POST', uri, headers, body: payload);
      response = await httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );
      _logResponse(response);
    } catch (e, st) {
      print('SinglePlayerGameRepositoryImpl.submitAnswer -> exception: $e');
      print(st);
      rethrow;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = _decodeBody(response.body);
      final questionResult = _buildQuestionResult(decoded, playerAnswer);
      final slide = _parseSlide(decoded['nextSlide']);
      final correctIndex = _extractCorrectAnswerIndex(decoded);
      final updatedGame = _tryExtractGame(
        decoded['attemptState'] ?? decoded['game'],
        fallbackAttemptId: attemptId,
      );
      return SubmitAnswerRepositoryResponse(
        evaluatedQuestion: questionResult,
        nextSlide: slide,
        correctAnswerIndex: correctIndex,
        updatedGame: updatedGame,
      );
    }

    throw Exception(
      'Failed to submit answer: ${response.statusCode} - ${response.body}',
    );
  }

  @override
  Future<SinglePlayerGame> getAttemptSummary(String attemptId) async {
    final uri = Uri.parse('$baseUrl/attempts/$attemptId/summary');
    http.Response response;
    final headers = await _buildJsonHeaders();
    try {
      print('SinglePlayerGameRepositoryImpl.getAttemptSummary -> GET $uri');
      _logRequest('GET', uri, headers);
      response = await httpClient.get(uri, headers: headers);
      _logResponse(response);
    } catch (e, st) {
      print('SinglePlayerGameRepositoryImpl.getAttemptSummary -> exception: $e');
      print(st);
      rethrow;
    }

    if (response.statusCode == 200) {
      final decoded = _decodeBody(response.body);
      return _extractGameFromPayload(
        decoded,
        fallbackAttemptId: attemptId,
      );
    }

    throw Exception(
      'Failed to fetch attempt summary: ${response.statusCode} - ${response.body}',
    );
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  SinglePlayerGame _extractGameFromPayload(
    Map<String, dynamic> payload, {
    String? fallbackKahootId,
    String? fallbackPlayerId,
    int? fallbackTotalQuestions,
    String? fallbackAttemptId,
  }) {
    try {
      if (payload.containsKey('game')) {
        final inner = Map<String, dynamic>.from(
          payload['game'] as Map,
        );
        return SinglePlayerGame.fromJson(inner);
      }

      if (payload.containsKey('gameId')) {
        return SinglePlayerGame.fromJson(payload);
      }
    } catch (e) {
      print('SinglePlayerGameRepositoryImpl -> failed to parse canonical game: $e');
    }

    final answers = _parseAnswers(payload['gameAnswers']);
    final attemptId =
        payload['attemptId']?.toString() ?? fallbackAttemptId ?? _randomAttemptId();
    final quizId = payload['quizId']?.toString() ?? fallbackKahootId ?? '';
    final playerId = payload['playerId']?.toString() ?? fallbackPlayerId ?? '';
    final totalQuestions = _asInt(
          payload['totalQuestions'] ?? payload['questionCount'],
        ) ??
        fallbackTotalQuestions ??
        answers.length;
    final score = _asInt(
          payload['currentScore'] ?? payload['finalScore'] ?? payload['score'],
        ) ??
        0;
    final correctCount = _asInt(
          payload['totalCorrect'] ?? payload['correctAnswers'] ?? payload['correctCount'],
        ) ??
        _countCorrectAnswers(answers);
    final accuracy = _asDouble(
          payload['accuracyPercentage'] ?? payload['accuracy'] ?? payload['accuracyPercent'],
        ) ??
        _accuracyFromCounts(correctCount, totalQuestions);
    final progress = _asDouble(payload['progress']) ?? _inferProgress(
          answered: answers.length,
          total: totalQuestions,
          state: payload['state'],
        );
    final state = _parseState(payload['state']);

    return SinglePlayerGame(
      gameId: attemptId,
      quizId: quizId,
      totalQuestions: totalQuestions,
      playerId: playerId,
      gameProgress: GameProgress(state: state, progress: progress),
      gameScore: GameScore(score: score),
      startedAt: _parseDate(payload['startedAt']) ?? DateTime.now(),
      completedAt: _parseDate(payload['completedAt']),
      gameAnswers: answers,
      totalCorrect: correctCount,
      accuracyPercentage: accuracy,
    );
  }

  List<QuestionResult> _parseAnswers(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => QuestionResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return <QuestionResult>[];
  }

  SinglePlayerGame? _tryExtractGame(
    dynamic payload, {
    String? fallbackAttemptId,
    String? fallbackKahootId,
    String? fallbackPlayerId,
    int? fallbackTotalQuestions,
  }) {
    if (payload is Map) {
      return _extractGameFromPayload(
        Map<String, dynamic>.from(payload),
        fallbackAttemptId: fallbackAttemptId,
        fallbackKahootId: fallbackKahootId,
        fallbackPlayerId: fallbackPlayerId,
        fallbackTotalQuestions: fallbackTotalQuestions,
      );
    }
    return null;
  }

  SlideDTO? _parseSlide(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final slideId = map['slideId']?.toString() ?? map['id']?.toString();
    if (slideId == null || slideId.isEmpty) return null;

    final questionText = map['questionText']?.toString() ?? '';
    final questionType = map['questionType']?.toString() ?? 'quiz';
    final timeLimit =
        _asInt(map['timeLimitSeconds'] ?? map['timeLimit']) ?? 20;
    final mediaUrl = map['mediaID']?.toString() ?? map['mediaUrl']?.toString();

    final optionsRaw = map['options'];
    final options = <SlideOptionDTO>[];
    if (optionsRaw is List) {
      for (var i = 0; i < optionsRaw.length; i++) {
        final optionEntry = optionsRaw[i];
        if (optionEntry is! Map) continue;
        final optionMap = Map<String, dynamic>.from(optionEntry);
        final index = _asInt(optionMap['index']) ?? i;
        final textValue = optionMap['text'] ?? optionMap['answerText'];
        final optMedia = optionMap['mediaID']?.toString() ??
            optionMap['mediaUrl']?.toString();
        options.add(
          SlideOptionDTO(
            index: index,
            text: textValue?.toString(),
            mediaUrl: optMedia,
          ),
        );
      }
    }

    return SlideDTO(
      slideId: slideId,
      questionText: questionText,
      questionType: questionType,
      timeLimitSeconds: timeLimit,
      mediaUrl: mediaUrl,
      options: options,
    );
  }

  int? _extractCorrectAnswerIndex(Map<String, dynamic> payload) {
    final dynamic value = payload['correctAnswerIndex'] ??
        payload['correctOptionIndex'] ??
        payload['correctOption'] ??
        payload['answerIndex'];
    return _asInt(value);
  }

  QuestionResult _buildQuestionResult(
    Map<String, dynamic> payload,
    PlayerAnswer originalAnswer,
  ) {
    if (payload.containsKey('questionResult')) {
      final inner = Map<String, dynamic>.from(payload['questionResult'] as Map);
      try {
        return QuestionResult.fromJson(inner);
      } catch (_) {
        // fall back to manual build
      }
    }

    final evaluatedJson = payload.containsKey('evaluatedAnswer')
        ? Map<String, dynamic>.from(payload['evaluatedAnswer'] as Map)
        : <String, dynamic>{
            'wasCorrect': payload['wasCorrect'] ?? false,
            'pointsEarned': _asInt(payload['pointsEarned']) ?? 0,
          };

    final evaluated = EvaluatedAnswer.fromJson(evaluatedJson);
    final questionId = payload['questionId']?.toString() ??
      payload['slideId']?.toString() ??
      originalAnswer.slideId ??
      'unknown_question';

    return QuestionResult(
      questionId: questionId,
      playerAnswer: originalAnswer,
      evaluatedAnswer: evaluated,
    );
  }

  GameProgressStatus _parseState(dynamic rawState) {
    if (rawState is String) {
      final normalized = rawState.trim().toUpperCase();
      for (final status in GameProgressStatus.values) {
        if (status.name == normalized) {
          return status;
        }
      }
    }
    return GameProgressStatus.IN_PROGRESS;
  }

  double _inferProgress({
    required int answered,
    required int total,
    dynamic state,
  }) {
    if (total <= 0) {
      return state?.toString().toUpperCase() == GameProgressStatus.COMPLETED.name
          ? 1.0
          : 0.0;
    }
    return (answered / total).clamp(0.0, 1.0);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  double? _asDouble(dynamic raw) {
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) {
      return double.tryParse(raw);
    }
    return null;
  }

  int _countCorrectAnswers(List<QuestionResult> answers) {
    return answers.where((entry) => entry.evaluatedAnswer.wasCorrect).length;
  }

  double? _accuracyFromCounts(int correctAnswers, int totalQuestions) {
    if (totalQuestions <= 0) return null;
    final ratio = correctAnswers / totalQuestions;
    return (ratio * 100).clamp(0.0, 100.0);
  }

  String _randomAttemptId() =>
      'attempt_${DateTime.now().millisecondsSinceEpoch}';
}
