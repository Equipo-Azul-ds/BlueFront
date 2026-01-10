// ENUM
enum GameStateType {
  lobby,
  questions,
  results,
  end;

  String toJson() {
    return switch (this) {
      GameStateType.lobby => 'LOBBY',
      GameStateType.questions => 'QUESTIONS',
      GameStateType.results => 'RESULTS',
      GameStateType.end => 'END',
    };
  }

  static GameStateType fromJson(String json) {
    final normalized = json.trim();
    return switch (normalized) {
      'LOBBY' || 'lobby' => GameStateType.lobby,
      'QUESTIONS' || 'questions' => GameStateType.questions,
      'RESULTS' || 'results' => GameStateType.results,
      'END' || 'end' => GameStateType.end,
      _ => GameStateType.lobby,
    };
  }
}

// Modelo de Agregado
class MultiplayerSession {
  final String sessionId;
  final String hostId;
  final String quizId;
  final GamePin gamePin;
  final DateTime startedAt;
  final GameState gameState;
  final int numberOfSlides;
  final int currentSlideIndex;
  final Map<String, Player> players;
  final Map<String, QuestionResults> sessionAnswers;

  MultiplayerSession({
    required this.sessionId,
    required this.hostId,
    required this.quizId,
    required this.gamePin,
    required this.startedAt,
    required this.gameState,
    required this.numberOfSlides,
    required this.currentSlideIndex,
    required this.players,
    required this.sessionAnswers,
  });

  factory MultiplayerSession.fromJson(Map<String, dynamic> json) {
    return MultiplayerSession(
      sessionId: json['sessionId'],
      hostId: json['hostId'],
      quizId: json['quizId'],
      gamePin: GamePin.fromJson(json['gamePin']),
      startedAt: DateTime.parse(json['startedAt']),
      gameState: GameState.fromJson(json['gameState']),
      numberOfSlides: json['numberOfSlides'] as int,
      currentSlideIndex: json['currentSlideIndex'] as int,
      players: (json['players'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Player.fromJson(value)),
      ),
      sessionAnswers: (json['sessionAnswers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, QuestionResults.fromJson(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'hostId': hostId,
      'quizId': quizId,
      'gamePin': gamePin.toJson(),
      'startedAt': startedAt.toIso8601String(),
      'gameState': gameState.toJson(),
      'numberOfSlides': numberOfSlides,
      'currentSlideIndex': currentSlideIndex,
      'players': players.map((key, value) => MapEntry(key, value.toJson())),
      'sessionAnswers': sessionAnswers.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }
}

// Modelos de Value Objects

class GamePin {
  final int pin;

  GamePin({required this.pin});

  factory GamePin.fromJson(Map<String, dynamic> json) {
    return GamePin(pin: json['pin'] as int);
  }

  Map<String, dynamic> toJson() => {'pin': pin};
}

class GameState {
  final GameStateType state;

  GameState({required this.state});

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(state: GameStateType.fromJson(json['state']));
  }

  Map<String, dynamic> toJson() => {'state': state.toJson()};
}

class QuestionResults {
  final String questionId;
  final Map<String, PlayerAnswer> answers;
  final Map<String, EvaluatedAnswer> evaluatedAnswers;

  QuestionResults({
    required this.questionId,
    required this.answers,
    required this.evaluatedAnswers,
  });

  factory QuestionResults.fromJson(Map<String, dynamic> json) {
    return QuestionResults(
      questionId: json['questionId'],
      answers: (json['answers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PlayerAnswer.fromJson(value)),
      ),
      evaluatedAnswers: (json['evaluatedAnswers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, EvaluatedAnswer.fromJson(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answers': answers.map((key, value) => MapEntry(key, value.toJson())),
      'evaluatedAnswers': evaluatedAnswers.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }
}

class PlayerAnswer {
  final String playerId;
  final String questionId;
  final List<int>? answerIndex;
  final int timeUsedMs;

  PlayerAnswer({
    required this.playerId,
    required this.questionId,
    this.answerIndex,
    required this.timeUsedMs,
  });

  factory PlayerAnswer.fromJson(Map<String, dynamic> json) {
    return PlayerAnswer(
      playerId: json['playerId'],
      questionId: json['questionId'],
      answerIndex: json['answerIndex'] == null
          ? null
          : (json['answerIndex'] is List)
          ? List<int>.from(json['answerIndex'])
          : [json['answerIndex'] as int],
      timeUsedMs: json['timeUsedMs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'questionId': questionId,
      'answerIndex': answerIndex,
      'timeUsedMs': timeUsedMs,
    };
  }
}

class EvaluatedAnswer {
  final String playerId;
  final bool wasCorrect;
  final int pointsEarned;

  EvaluatedAnswer({
    required this.playerId,
    required this.wasCorrect,
    required this.pointsEarned,
  });

  factory EvaluatedAnswer.fromJson(Map<String, dynamic> json) {
    return EvaluatedAnswer(
      playerId: json['playerId'],
      wasCorrect: json['wasCorrect'] as bool,
      pointsEarned: json['pointsEarned'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'wasCorrect': wasCorrect,
      'pointsEarned': pointsEarned,
    };
  }
}

// Modelo de Entidad

class Player {
  final String playerId;
  final String nickname;
  final int score;
  final int streak;

  Player({
    required this.playerId,
    required this.nickname,
    required this.score,
    required this.streak,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      playerId: json['playerId'],
      nickname: json['nickname'],
      score: json['score'] as int,
      streak: json['streak'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'nickname': nickname,
      'score': score,
      'streak': streak,
    };
  }
}
