/// Estado del lobby para el anfitrión (lista de jugadores conectados y fase).
class HostLobbyUpdateEvent {
  HostLobbyUpdateEvent({required this.state, required this.players, this.numberOfPlayers});

  final String state;
  final List<SessionPlayerSummary> players;
  final int? numberOfPlayers;

  factory HostLobbyUpdateEvent.fromJson(Map<String, dynamic> json) {
    final playersRaw = json['players'];
    final players = <SessionPlayerSummary>[];
    if (playersRaw is List) {
      for (final entry in playersRaw) {
        if (entry is Map) {
          players.add(SessionPlayerSummary.fromJson(_asMap(entry)));
        }
      }
    }
    return HostLobbyUpdateEvent(
      state: _string(json['state'], fallback: 'lobby'),
      players: List.unmodifiable(players),
      numberOfPlayers: _int(json['numberOfPlayers']),
    );
  }
}

/// Estado inicial/sincronización de un jugador al entrar al lobby.
class PlayerConnectedEvent {
  PlayerConnectedEvent({required this.state, required this.nickname, required this.score, required this.connectedBefore});

  final String state;
  final String nickname;
  final int score;
  final bool connectedBefore;

  factory PlayerConnectedEvent.fromJson(Map<String, dynamic> json) {
    return PlayerConnectedEvent(
      state: _string(json['state'], fallback: 'lobby'),
      nickname: _string(json['nickname'], fallback: 'Jugador'),
      score: _int(json['score']) ?? 0,
      connectedBefore: _bool(json['connectedBefore']) ?? false,
    );
  }
}

/// Snapshot de inicio de pregunta: slide actual + tiempo restante opcional.
class QuestionStartedEvent {
  QuestionStartedEvent({required this.state, required this.slide, this.timeRemainingMs, this.hasAnswered});

  final String state;
  final SlideData slide;
  final int? timeRemainingMs;
  final bool? hasAnswered;

  factory QuestionStartedEvent.fromJson(Map<String, dynamic> json) {
    final slideData = json['currentSlideData'];
    final slide = SlideData.fromJson(slideData is Map ? _asMap(slideData) : const <String, dynamic>{});
    return QuestionStartedEvent(
      state: _string(json['state'], fallback: 'question'),
      slide: slide,
      timeRemainingMs: _int(json['timeRemainingMs']),
      hasAnswered: _bool(json['hasAnswered']),
    );
  }
}

/// Resultados de la pregunta para el host (ranking y distribución de respuestas).
class HostResultsEvent {
  HostResultsEvent({required this.state, required this.correctAnswerIds, required this.leaderboard, required this.stats, required this.progress});

  final String state;
  final List<String> correctAnswerIds;
  final List<LeaderboardEntry> leaderboard;
  final ResultsStats stats;
  final ProgressInfo progress;

  factory HostResultsEvent.fromJson(Map<String, dynamic> json) {
    return HostResultsEvent(
      state: _string(json['state'], fallback: 'results'),
      correctAnswerIds: _stringList(json['correctAnswerId']) ?? _stringList(json['correctAnswerIds']) ?? const <String>[],
      leaderboard: _parseList(json['leaderboard'], (map) => LeaderboardEntry.fromJson(map)),
      stats: ResultsStats.fromJson(json['stats'] is Map ? _asMap(json['stats']) : const <String, dynamic>{}),
      progress: ProgressInfo.fromJson(json['progress'] is Map ? _asMap(json['progress']) : const <String, dynamic>{}),
    );
  }
}

/// Resultados de la pregunta para un jugador (puntos, posición, streak).
class PlayerResultsEvent {
  PlayerResultsEvent({required this.isCorrect, required this.pointsEarned, required this.totalScore, required this.rank, required this.previousRank, required this.streak, required this.correctAnswerIds, required this.progress, required this.message});

  final bool isCorrect;
  final int pointsEarned;
  final int totalScore;
  final int rank;
  final int previousRank;
  final int streak;
  final List<String> correctAnswerIds;
  final ProgressInfo progress;
  final String message;

  factory PlayerResultsEvent.fromJson(Map<String, dynamic> json) {
    return PlayerResultsEvent(
      isCorrect: _bool(json['isCorrect']) ?? false,
      pointsEarned: _int(json['pointsEarned']) ?? 0,
      totalScore: _int(json['totalScore']) ?? 0,
      rank: _int(json['rank']) ?? 0,
      previousRank: _int(json['previousRank']) ?? 0,
      streak: _int(json['streak']) ?? 0,
      correctAnswerIds: _stringList(json['correctAnswerIds']) ?? const <String>[],
      progress: ProgressInfo.fromJson(json['progress'] is Map ? _asMap(json['progress']) : const <String, dynamic>{}),
      message: _string(json['message'], fallback: ''),
    );
  }
}

/// Podio final enviado al host al terminar la partida.
class HostGameEndEvent {
  HostGameEndEvent({required this.state, required this.finalPodium, required this.winner, required this.totalParticipants, this.totalQuestions});

  final String state;
  final List<LeaderboardEntry> finalPodium;
  final LeaderboardEntry? winner;
  final int totalParticipants;
  final int? totalQuestions;

  factory HostGameEndEvent.fromJson(Map<String, dynamic> json) {
    final podium = _parseList(json['finalPodium'], (map) => LeaderboardEntry.fromJson(map));
    final winner = json['winner'] is Map ? LeaderboardEntry.fromJson(_asMap(json['winner'])) : null;
    return HostGameEndEvent(
      state: _string(json['state'], fallback: 'end'),
      finalPodium: podium,
      winner: winner,
      totalParticipants: _int(json['totalParticipants']) ?? podium.length,
      totalQuestions: _int(json['totalQuestions'] ?? json['totalSlides']),
    );
  }
}

/// Resumen final para un jugador al cerrar la partida.
class PlayerGameEndEvent {
  PlayerGameEndEvent({
    required this.state,
    required this.rank,
    required this.totalScore,
    required this.isPodium,
    required this.isWinner,
    required this.finalStreak,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.answers,
  });

  final String state;
  final int rank;
  final int totalScore;
  final bool isPodium;
  final bool isWinner;
  final int finalStreak;
  final int totalQuestions;
  final int correctAnswers;
  final List<PlayerAnswerSummary> answers;

  factory PlayerGameEndEvent.fromJson(Map<String, dynamic> json) {
    final answers = _parseAnswerSummaries(json);
    final totalQuestions = _int(
          json['totalQuestions'] ??
          json['totalSlides'] ??
          json['questionCount'] ??
          answers.length,
        ) ??
        answers.length;
    final inferredCorrect = answers.where((a) => a.wasCorrect == true).length;
    final correctAnswers = _int(
          json['correctAnswers'] ??
          json['correctCount'] ??
          json['correct'],
        ) ??
        inferredCorrect;

    return PlayerGameEndEvent(
      state: _string(json['state'], fallback: 'end'),
      rank: _int(json['rank']) ?? 0,
      totalScore: _int(json['totalScore'] ?? json['score'] ?? json['points']) ?? 0,
      isPodium: _bool(json['isPodium']) ?? false,
      isWinner: _bool(json['isWinner']) ?? false,
      finalStreak: _int(json['finalStreak']) ?? 0,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      answers: List.unmodifiable(_fillAnswerGaps(answers, totalQuestions)),
    );
  }
}

/// Cierre remoto de sesión (host la finalizó o error fatal).
class SessionClosedEvent {
  SessionClosedEvent({required this.reason, required this.message});

  final String reason;
  final String message;

  factory SessionClosedEvent.fromJson(Map<String, dynamic> json) {
    return SessionClosedEvent(
      reason: _string(json['reason'], fallback: ''),
      message: _string(json['message'], fallback: ''),
    );
  }
}

/// Contador de respuestas enviadas durante la pregunta (sólo host).
class HostAnswerUpdateEvent {
  HostAnswerUpdateEvent({required this.numberOfSubmissions});

  final int numberOfSubmissions;

  factory HostAnswerUpdateEvent.fromJson(Map<String, dynamic> json) {
    return HostAnswerUpdateEvent(numberOfSubmissions: _int(json['numberOfSubmissions']) ?? 0);
  }
}

// Aviso de desconexión/abandono de un jugador.
class PlayerLeftSessionEvent {
  PlayerLeftSessionEvent({required this.userId, required this.nickname, required this.message});

  final String? userId;
  final String? nickname;
  final String? message;

  factory PlayerLeftSessionEvent.fromJson(Map<String, dynamic> json) {
    return PlayerLeftSessionEvent(
      userId: _nullableString(json['userId']),
      nickname: _nullableString(json['nickname']),
      message: _nullableString(json['message']),
    );
  }
}

// Aviso a jugadores de que el host se fue.
class HostLeftSessionEvent {
  HostLeftSessionEvent({required this.message});

  final String? message;

  factory HostLeftSessionEvent.fromJson(Map<String, dynamic> json) {
    return HostLeftSessionEvent(message: _nullableString(json['message']));
  }
}

// Aviso a jugadores de que el host regresó.
class HostReturnedSessionEvent {
  HostReturnedSessionEvent({required this.message});

  final String? message;

  factory HostReturnedSessionEvent.fromJson(Map<String, dynamic> json) {
    return HostReturnedSessionEvent(message: _nullableString(json['message']));
  }
}

// Error de sincronización al reconstruir estado; el server suele cerrar.
class SyncErrorEvent {
  SyncErrorEvent({required this.message});

  final String? message;

  factory SyncErrorEvent.fromJson(Map<String, dynamic> json) {
    return SyncErrorEvent(message: _nullableString(json['message']));
  }
}

// Error de conexión sólo para el emisor (p. ej. nickname inválido).
class ConnectionErrorEvent {
  ConnectionErrorEvent({required this.message});

  final String? message;

  factory ConnectionErrorEvent.fromJson(Map<String, dynamic> json) {
    return ConnectionErrorEvent(message: _nullableString(json['message']));
  }
}

class PlayerAnswerSummary {
  const PlayerAnswerSummary({required this.index, required this.wasCorrect});

  final int index;
  final bool? wasCorrect;
}

// Slide de una pregunta en tiempo real (usado tanto por host como jugador).
class SlideData {
  const SlideData({
    required this.id,
    required this.position,
    required this.slideType,
    required this.timeLimitSeconds,
    required this.questionText,
    required this.imageUrl,
    required this.pointsValue,
    required this.options,
    required this.isMultiSelect,
    required this.maxSelections,
  });

  final String id;
  final int position;
  final String slideType;
  final int timeLimitSeconds;
  final String questionText;
  final String? imageUrl;
  final int pointsValue;
  final bool isMultiSelect;
  final int? maxSelections;
  final List<SlideOption> options;

  factory SlideData.fromJson(Map<String, dynamic> json) {
    return SlideData(
      id: _string(json['id'] ?? json['slideId'] ?? json['questionId'], fallback: ''),
      position: _int(json['position']) ?? 0,
      slideType: _string(json['slideType'], fallback: ''), // API usa slideType; questionType es compat.
      timeLimitSeconds: _int(json['timeLimitSeconds'] ?? json['timeLimit']) ?? 0,
      questionText: _string(json['questionText'] ?? json['question'], fallback: 'Pregunta'),
      imageUrl: _nullableString(json['slideImageURL'] ?? json['imageUrl'] ?? json['mediaURL'] ?? json['mediaUrl'] ?? json['coverImageUrl']),
      pointsValue: _int(json['pointsValue']) ?? 0,
      isMultiSelect: _supportsMultipleAnswers(json),
      maxSelections: _parseMaxSelections(json),
      options: _parseList(json['options'], (map) => SlideOption.fromJson(map)),
    );
  }
}

class SlideOption {
  const SlideOption({required this.id, required this.text, this.mediaUrl});

  final String id;
  final String text;
  final String? mediaUrl;

  factory SlideOption.fromJson(Map<String, dynamic> json) {
    return SlideOption(
      id: _string(json['id'] ?? json['index'] ?? json['optionId'] ?? json['answerId'], fallback: ''),
      text: _string(json['text'] ?? json['label'] ?? json['answer'] ?? json['value'], fallback: 'Opción'),
      mediaUrl: _nullableString(json['mediaURL'] ?? json['mediaUrl']),
    );
  }
}

class ResultsStats {
  ResultsStats({required this.totalAnswers, required this.distribution});

  final int totalAnswers;
  final Map<String, int> distribution;

  factory ResultsStats.fromJson(Map<String, dynamic> json) {
    final distributionRaw = json['distribution'];
    final distribution = <String, int>{};
    if (distributionRaw is Map) {
      final map = _asMap(distributionRaw);
      for (final entry in map.entries) {
        distribution[entry.key.toString()] = _int(entry.value) ?? 0;
      }
    }
    return ResultsStats(
      totalAnswers: _int(json['totalAnswers']) ?? distribution.values.fold(0, (p, e) => p + e),
      distribution: distribution,
    );
  }
}

class ProgressInfo {
  ProgressInfo({required this.current, required this.total, required this.isLastSlide});

  final int current;
  final int total;
  final bool isLastSlide;

  factory ProgressInfo.fromJson(Map<String, dynamic> json) {
    return ProgressInfo(
      current: _int(json['current']) ?? 0,
      total: _int(json['total']) ?? 0,
      isLastSlide: _bool(json['isLastSlide']) ?? false,
    );
  }
}

class LeaderboardEntry {
  LeaderboardEntry({required this.playerId, required this.nickname, required this.score, required this.rank, required this.previousRank});

  final String playerId;
  final String nickname;
  final int score;
  final int rank;
  final int previousRank;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerId: _string(json['playerId'] ?? json['id'], fallback: ''),
      nickname: _string(json['nickname'] ?? json['name'], fallback: 'Jugador'),
      score: _int(json['score'] ?? json['points']) ?? 0,
      rank: _int(json['rank']) ?? 0,
      previousRank: _int(json['previousRank']) ?? 0,
    );
  }
}

class SessionPlayerSummary {
  SessionPlayerSummary({required this.playerId, required this.nickname});

  final String playerId;
  final String nickname;

  factory SessionPlayerSummary.fromJson(Map<String, dynamic> json) {
    return SessionPlayerSummary(
      playerId: _string(json['playerId'] ?? json['id'], fallback: ''),
      nickname: _string(json['nickname'], fallback: 'Jugador'),
    );
  }
}

bool _supportsMultipleAnswers(Map<String, dynamic> json) {
  final allowRaw = json['allowMultipleAnswers'] ?? json['multipleAnswers'] ?? json['isMultipleSelect'] ?? json['multiSelect'];
  final allow = _bool(allowRaw);
  if (allow != null) return allow;

  final maxSelections = _parseMaxSelections(json);
  if (maxSelections != null && maxSelections > 1) return true;

  // Compat: slideType (API) / questionType (legacy) pueden venir como enums.
  // Soportamos valores tipo MULTI_SELECT | MULTIPLE_ANSWER y dejamos fallback por substring.
  final slideType = _string(json['slideType'] ?? json['questionType'], fallback: '');
  if (_isMultiType(slideType)) return true;
  return false;
}

bool _isMultiType(String rawType) {
  final normalized = rawType.trim().toLowerCase();
  if (normalized.isEmpty) return false;

  // Placeholder enum support until backend enum list is finalized.
  const multiEnums = <String>{
    'multi_select',
    'multiple_select',
    'multiple_choice',
    'multiple_answer',
    'multiple_answers',
    'multi_answer',
    'multi_answers',
    'checkbox',
  };
  if (multiEnums.contains(normalized)) return true;

  // Broad fallback for legacy strings.
  return normalized.contains('multi') || normalized.contains('multiple') || normalized.contains('checkbox');
}

int? _parseMaxSelections(Map<String, dynamic> json) {
  final raw = json['maxAnswers'] ?? json['maxSelections'] ?? json['maxChoices'];
  return _int(raw);
}

List<PlayerAnswerSummary> _parseAnswerSummaries(Map<String, dynamic> json) {
  final resultMap = <int, PlayerAnswerSummary>{};
  final sources = [json['answers'], json['answerSummaries'], json['questionResults'], json['slides']];

  for (final source in sources) {
    if (source is List) {
      for (var i = 0; i < source.length; i++) {
        final entry = source[i];
        if (entry is Map) {
          final map = Map<String, dynamic>.from(entry);
          final index = _int(map['index'] ?? map['questionIndex'] ?? i) ?? i;
          final wasCorrect = _bool(map['correct'] ?? map['isCorrect'] ?? map['answeredCorrectly']);
          resultMap[index] = PlayerAnswerSummary(index: index, wasCorrect: wasCorrect);
        } else if (entry is bool) {
          resultMap[i] = PlayerAnswerSummary(index: i, wasCorrect: entry);
        }
      }
    }
  }

  if (resultMap.isEmpty) {
    final fallbackCount = _int(json['totalQuestions'] ?? json['totalSlides'] ?? json['questionCount']);
    if (fallbackCount == null || fallbackCount <= 0) return const <PlayerAnswerSummary>[];
    return List.generate(
      fallbackCount,
      (index) => PlayerAnswerSummary(index: index, wasCorrect: null),
    );
  }

  final sortedKeys = resultMap.keys.toList()..sort();
  return sortedKeys.map((k) => resultMap[k]!).toList(growable: false);
}

List<PlayerAnswerSummary> _fillAnswerGaps(
  List<PlayerAnswerSummary> answers,
  int totalQuestions,
) {
  if (totalQuestions <= 0) return answers;
  final map = <int, PlayerAnswerSummary>{
    for (final answer in answers) answer.index: answer,
  };
  for (var i = 0; i < totalQuestions; i++) {
    map.putIfAbsent(i, () => PlayerAnswerSummary(index: i, wasCorrect: null));
  }
  final keys = map.keys.toList()..sort();
  return keys.map((k) => map[k]!).toList(growable: false);
}

// Helpers
Map<String, dynamic> _asMap(Map input) => Map<String, dynamic>.from(input);

String _string(dynamic value, {required String fallback}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == 'yes' || lower == 'correct') return true;
    if (lower == 'false' || lower == 'no' || lower == 'incorrect') return false;
  }
  return null;
}

List<String>? _stringList(dynamic raw) {
  if (raw is List) {
    final result = <String>[];
    for (final entry in raw) {
      final text = entry?.toString();
      if (text != null && text.isNotEmpty) {
        result.add(text);
      }
    }
    return result;
  }
  return null;
}

List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) mapper) {
  if (raw is List) {
    final result = <T>[];
    for (final entry in raw) {
      if (entry is Map) {
        result.add(mapper(_asMap(entry)));
      }
    }
    return List.unmodifiable(result);
  }
  return List<T>.empty();
}
