// ENUM
enum GameProgressStatus {
  IN_PROGRESS,
  COMPLETED;

  String toJson() => name;

  static GameProgressStatus fromJson(String json) {
    return GameProgressStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => GameProgressStatus.IN_PROGRESS,
    );
  }
}

// AGGREGATE ROOT
class SinglePlayerGame {
  final String gameId;
  final String quizId;
  final int totalQuestions;
  final String playerId;
  final GameProgress gameProgress;
  final GameScore gameScore;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<QuestionResult> gameAnswers;

  SinglePlayerGame({
    required this.gameId,
    required this.quizId,
    required this.totalQuestions,
    required this.playerId,
    required this.gameProgress,
    required this.gameScore,
    required this.startedAt,
    this.completedAt,
    required this.gameAnswers,
  });

  factory SinglePlayerGame.fromJson(Map<String, dynamic> json) {
    return SinglePlayerGame(
      gameId: json['gameId'],
      quizId: json['quizId'],
      totalQuestions: json['totalQuestions'],
      playerId: json['playerId'],
      gameProgress: GameProgress.fromJson(json['gameProgress']),
      gameScore: GameScore.fromJson(json['gameScore']),
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      gameAnswers: (json['gameAnswers'] as List<dynamic>)
          .map((e) => QuestionResult.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'quizId': quizId,
      'totalQuestions': totalQuestions,
      'playerId': playerId,
      'gameProgress': gameProgress.toJson(),
      'gameScore': gameScore.toJson(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'gameAnswers': gameAnswers.map((e) => e.toJson()).toList(),
    };
  }
}

// VALUE OBJECTS

class GameProgress {
  final GameProgressStatus state;
  final double progress;

  GameProgress({required this.state, required this.progress});

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      state: GameProgressStatus.fromJson(json['state']),
      progress: (json['progress'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'state': state.toJson(), 'progress': progress};
  }
}

class GameScore {
  final int score;

  GameScore({required this.score});

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(score: json['score'] as int);
  }

  Map<String, dynamic> toJson() => {'score': score};
}

class QuestionResult {
  final String questionId;
  final PlayerAnswer playerAnswer;
  final EvaluatedAnswer evaluatedAnswer;

  QuestionResult({
    required this.questionId,
    required this.playerAnswer,
    required this.evaluatedAnswer,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId'],
      playerAnswer: PlayerAnswer.fromJson(json['playerAnswer']),
      evaluatedAnswer: EvaluatedAnswer.fromJson(json['evaluatedAnswer']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'playerAnswer': playerAnswer.toJson(),
      'evaluatedAnswer': evaluatedAnswer.toJson(),
    };
  }
}

class PlayerAnswer {
  final List<int>? answerIndex;
  final int timeUsedMs;

  PlayerAnswer({this.answerIndex, required this.timeUsedMs});

  factory PlayerAnswer.fromJson(Map<String, dynamic> json) {
    return PlayerAnswer(
      answerIndex: json['answerIndex'] == null
          ? null
          : (json['answerIndex'] is List)
          ? List<int>.from(json['answerIndex'])
          : [json['answerIndex'] as int],
      timeUsedMs: json['timeUsedMs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'answerIndex': answerIndex, 'timeUsedMs': timeUsedMs};
  }
}

class EvaluatedAnswer {
  final bool wasCorrect;
  final int pointsEarned;

  EvaluatedAnswer({required this.wasCorrect, required this.pointsEarned});

  factory EvaluatedAnswer.fromJson(Map<String, dynamic> json) {
    return EvaluatedAnswer(
      wasCorrect: json['wasCorrect'] as bool,
      pointsEarned: json['pointsEarned'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'wasCorrect': wasCorrect, 'pointsEarned': pointsEarned};
  }
}
