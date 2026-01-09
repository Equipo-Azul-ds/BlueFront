import 'dart:convert';

/// Tipo de juego para diferenciar attempts single player vs sesiones multijugador.
enum GameType { singleplayer, multiplayer }

GameType gameTypeFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'singleplayer':
      return GameType.singleplayer;
    case 'multiplayer':
      return GameType.multiplayer;
    default:
      return GameType.multiplayer;
  }
}

/// Resumen paginado de los resultados personales (endpoint my-results).
class ReportSummary {
  ReportSummary({
    required this.kahootId,
    required this.gameId,
    required this.gameType,
    required this.title,
    required this.completionDate,
    required this.finalScore,
    this.rankingPosition,
  });

  final String kahootId;
  final String gameId;
  final GameType gameType;
  final String title;
  final DateTime completionDate;
  final int finalScore;
  final int? rankingPosition;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      kahootId: json['kahootId']?.toString() ?? '',
      gameId: json['gameId']?.toString() ?? '',
      gameType: gameTypeFromString(json['gameType']?.toString()),
      title: json['title']?.toString() ?? '',
      completionDate: DateTime.tryParse(json['completionDate']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      finalScore: json['finalScore'] is num ? (json['finalScore'] as num).toInt() : 0,
      rankingPosition: json['rankingPosition'] is num ? (json['rankingPosition'] as num).toInt() : null,
    );
  }
}

class PlayerRankingEntry {
  PlayerRankingEntry({
    required this.position,
    required this.username,
    required this.score,
    required this.correctAnswers,
  });

  final int position;
  final String username;
  final int score;
  final int correctAnswers;

  factory PlayerRankingEntry.fromJson(Map<String, dynamic> json) {
    return PlayerRankingEntry(
      position: json['position'] is num ? (json['position'] as num).toInt() : 0,
      username: json['username']?.toString() ?? '',
      score: json['score'] is num ? (json['score'] as num).toInt() : 0,
      correctAnswers: json['correctAnswers'] is num ? (json['correctAnswers'] as num).toInt() : 0,
    );
  }
}

class QuestionAnalysisEntry {
  QuestionAnalysisEntry({
    required this.questionIndex,
    required this.questionText,
    required this.correctPercentage,
  });

  final int questionIndex;
  final String questionText;
  final double correctPercentage;

  factory QuestionAnalysisEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['correctPercentage'];
    return QuestionAnalysisEntry(
      questionIndex: json['questionIndex'] is num ? (json['questionIndex'] as num).toInt() : 0,
      questionText: json['questionText']?.toString() ?? '',
      correctPercentage: raw is num ? raw.toDouble() : 0,
    );
  }
}

/// Informe completo de sesión (host).
class SessionReport {
  SessionReport({
    required this.reportId,
    required this.sessionId,
    required this.title,
    required this.executionDate,
    required this.playerRanking,
    required this.questionAnalysis,
  });

  final String reportId;
  final String sessionId;
  final String title;
  final DateTime executionDate;
  final List<PlayerRankingEntry> playerRanking;
  final List<QuestionAnalysisEntry> questionAnalysis;

  factory SessionReport.fromJson(Map<String, dynamic> json) {
    final rankingRaw = json['playerRanking'] as List<dynamic>? ?? const [];
    final questionRaw = json['questionAnalysis'] as List<dynamic>? ?? const [];
    return SessionReport(
      reportId: json['reportId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      executionDate: DateTime.tryParse(json['executionDate']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      playerRanking: rankingRaw
          .whereType<Map<String, dynamic>>()
          .map(PlayerRankingEntry.fromJson)
          .toList(),
      questionAnalysis: questionRaw
          .whereType<Map<String, dynamic>>()
          .map(QuestionAnalysisEntry.fromJson)
          .toList(),
    );
  }
}

class QuestionResultEntry {
  QuestionResultEntry({
    required this.questionIndex,
    required this.questionText,
    required this.isCorrect,
    required this.answerText,
    required this.answerMediaIds,
    required this.timeTakenMs,
  });

  final int questionIndex;
  final String questionText;
  final bool isCorrect;
  final List<String> answerText;
  final List<String> answerMediaIds;
  final int timeTakenMs;

  factory QuestionResultEntry.fromJson(Map<String, dynamic> json) {
    return QuestionResultEntry(
      questionIndex: json['questionIndex'] is num ? (json['questionIndex'] as num).toInt() : 0,
      questionText: json['questionText']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      answerText: (json['answerText'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      answerMediaIds: (json['answerMediaID'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      timeTakenMs: json['timeTakenMs'] is num ? (json['timeTakenMs'] as num).toInt() : 0,
    );
  }
}

/// Resultado personal (multi y single). En multi incluye rankingPosition.
class PersonalResult {
  PersonalResult({
    required this.kahootId,
    required this.title,
    required this.userId,
    required this.finalScore,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.averageTimeMs,
    required this.questionResults,
    this.rankingPosition,
  });

  final String kahootId;
  final String title;
  final String userId;
  final int finalScore;
  final int correctAnswers;
  final int totalQuestions;
  final int averageTimeMs;
  final List<QuestionResultEntry> questionResults;
  final int? rankingPosition; // null en singleplayer

  factory PersonalResult.fromJson(Map<String, dynamic> json) {
    final questionRaw = json['questionResults'] as List<dynamic>? ?? const [];
    return PersonalResult(
      kahootId: json['kahootId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      finalScore: json['finalScore'] is num ? (json['finalScore'] as num).toInt() : 0,
      correctAnswers: json['correctAnswers'] is num ? (json['correctAnswers'] as num).toInt() : 0,
      totalQuestions: json['totalQuestions'] is num ? (json['totalQuestions'] as num).toInt() : 0,
      averageTimeMs: json['averageTimeMs'] is num ? (json['averageTimeMs'] as num).toInt() : 0,
      questionResults: questionRaw
          .whereType<Map<String, dynamic>>()
          .map(QuestionResultEntry.fromJson)
          .toList(),
      rankingPosition: json['rankingPosition'] is num ? (json['rankingPosition'] as num).toInt() : null,
    );
  }
}

/// Meta de paginación para listados.
class PaginationMeta {
  PaginationMeta({
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.limit,
  });

  final int totalItems;
  final int currentPage;
  final int totalPages;
  final int limit;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      totalItems: json['totalItems'] is num ? (json['totalItems'] as num).toInt() : 0,
      currentPage: json['currentPage'] is num ? (json['currentPage'] as num).toInt() : 1,
      totalPages: json['totalPages'] is num ? (json['totalPages'] as num).toInt() : 1,
      limit: json['limit'] is num ? (json['limit'] as num).toInt() : 20,
    );
  }
}

/// Respuesta paginada para los resultados personales.
class MyResultsResponse {
  MyResultsResponse({required this.results, required this.meta});

  final List<ReportSummary> results;
  final PaginationMeta meta;

  factory MyResultsResponse.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'] as List<dynamic>? ?? const [];
    return MyResultsResponse(
      results: resultsRaw
          .whereType<Map<String, dynamic>>()
          .map(ReportSummary.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

/// Utilidad para parsear respuestas HTTP a Map.
Map<String, dynamic> decodeJsonMap(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('Respuesta JSON inesperada');
}
