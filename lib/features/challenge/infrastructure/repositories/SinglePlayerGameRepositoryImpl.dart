import 'dart:async';
import '../../domain/entities/SinglePlayerGame.dart';
import '../../domain/repositories/SinglePlayerGameRepository.dart';

/// Por ahora Mockea respuestas de la API
class SinglePlayerGameRepositoryImpl implements SinglePlayerGameRepository {
  final Map<String, SinglePlayerGame> _store = {};
  // Track para las preguntas
  final Map<String, int> _positions = {};
  // Banco de preguntas como Payloads
  final Map<String, List<Map<String, dynamic>>> _questionBank = {
    'mock_quiz_1': [
      {
        'questionId': 'q1',
        'quizId': 'mock_quiz_1',
        'text': 'Cual es la capital de Francia?',
        'type': 'quiz',
        'timeLimit': 20,
        'points': 1000,
        'answers': [
          {'answerId': 'a1', 'text': 'Berlin'},
          {'answerId': 'a2', 'text': 'Madrid'},
          {'answerId': 'a3', 'text': 'Paris'},
          {'answerId': 'a4', 'text': 'Rome'},
        ]
      },
      {
        'questionId': 'q2',
        'quizId': 'mock_quiz_1',
        'text': 'Que Planeta es conocido como el mas Rojo?',
        'type': 'quiz',
        'timeLimit': 20,
        'points': 1000,
        'answers': [
          {'answerId': 'a1', 'text': 'Venus'},
          {'answerId': 'a2', 'text': 'Mars'},
        ]
      },
      {
        'questionId': 'q3',
        'quizId': 'mock_quiz_1',
        'text': 'Cuanto es 788 + 160?',
        'type': 'quiz',
        'timeLimit': 20,
        'points': 1000,
        'answers': [
          {'answerId': 'a1', 'text': '948'},
          {'answerId': 'a2', 'text': '958'},
          {'answerId': 'a3', 'text': '938'},
        ]
      },
      {
        'questionId': 'q4',
        'quizId': 'mock_quiz_1',
        'text': 'El Sol es una estrella?',
        'type': 'true_false',
        'timeLimit': 15,
        'points': 500,
        'answers': [
          {'answerId': 'a1', 'text': 'Verdadero'},
          {'answerId': 'a2', 'text': 'Falso'},
        ]
      }
    ]
  };

  // El Backend se encarga de determinar si la respuesta es correcta o no, esto mockea el valor interno
  final Map<String, int> _correctAnswerIndex = {
    'q1': 2,
    'q2': 1,
    'q3': 0,
    'q4': 0,
  };

  @override
  Future<SinglePlayerGame> createGame({required String quizId, required String playerId, required int totalQuestions}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final gameId = 'game_${now.millisecondsSinceEpoch}';

    final game = SinglePlayerGame(
      gameId: gameId,
      quizId: quizId,
      totalQuestions: totalQuestions,
      playerId: playerId,
      gameProgress: GameProgress(state: GameProgressStatus.IN_PROGRESS, progress: 0.0),
      gameScore: GameScore(score: 0),
      startedAt: now,
      completedAt: null,
      gameAnswers: [],
    );

    _store[gameId] = game;
    // Empieza el tracking de preguntas
    _positions[gameId] = 0;
    return game;
  }

  /// Esto es para la primera pregunta
  Map<String, dynamic>? getNextQuestionPayload(String gameId) {
    final game = _store[gameId];
    if (game == null) return null;
    final bank = _questionBank[game.quizId] ?? [];
    final pos = _positions[gameId] ?? 0;
    if (pos < bank.length && game.gameAnswers.length < game.totalQuestions) return bank[pos];
    return null;
  }

  /// Retorna el index correcto de la pregunta para la UI
  int? getCorrectAnswerIndex(String gameId, String questionId) {
    return _correctAnswerIndex[questionId];
  }

  Map<String, dynamic>? submitAnswerAndGetNextPayload(String gameId, String questionId, PlayerAnswer playerAnswer) {
    // Evaluación simulada (mock): evalúa usando la clave interna,
    // persiste el resultado en el almacén de dominio y retorna el siguiente payload.
    final game = _store[gameId];
    if (game == null) throw Exception('Game not found');

    // Determina la respuesta correcta usando el index interno
    final correctIndex = _correctAnswerIndex[questionId];
    final chosenIndex = (playerAnswer.answerIndex == null || playerAnswer.answerIndex!.isEmpty) ? null : playerAnswer.answerIndex!.first;
    final wasCorrect = (chosenIndex != null && correctIndex != null && chosenIndex == correctIndex);

    // Calcula los puntos basados en el tiempo usado por el jugador (server-side).
    // El API calcula puntos proporcionalmente al tiempo restante.
    final int basePoints = _getPointsForQuestion(questionId);
    final int timeLimitSeconds = _getTimeLimitForQuestion(questionId);
    final double timeUsedSeconds = (playerAnswer.timeUsedMs / 1000.0);
    final double multiplier = timeLimitSeconds > 0 ? ((timeLimitSeconds - timeUsedSeconds) / timeLimitSeconds) : 0.0;
    final int pointsEarned = wasCorrect ? (basePoints * (multiplier.clamp(0.0, 1.0))).round() : 0;
    final evaluated = EvaluatedAnswer(wasCorrect: wasCorrect, pointsEarned: pointsEarned);
    final qr = QuestionResult(questionId: questionId, playerAnswer: playerAnswer, evaluatedAnswer: evaluated);

    // Persistencia
    final updatedAnswers = List<QuestionResult>.from(game.gameAnswers)..add(qr);
    final progress = (updatedAnswers.length / (game.totalQuestions == 0 ? 1 : game.totalQuestions));
    final updatedScore = game.gameScore.score + evaluated.pointsEarned;

    final updatedGame = SinglePlayerGame(
      gameId: game.gameId,
      quizId: game.quizId,
      totalQuestions: game.totalQuestions,
      playerId: game.playerId,
      gameProgress: GameProgress(state: progress >= 1.0 ? GameProgressStatus.COMPLETED : GameProgressStatus.IN_PROGRESS, progress: progress),
      gameScore: GameScore(score: updatedScore),
      startedAt: game.startedAt,
      completedAt: progress >= 1.0 ? DateTime.now() : null,
      gameAnswers: updatedAnswers,
    );

    _store[gameId] = updatedGame;

    // Avanza la posición y retorna la siguiente pregunta si está disponible
    final bank = _questionBank[updatedGame.quizId] ?? [];
    final pos = (_positions[gameId] ?? 0);
    final nextIndex = pos + 1;
    if (nextIndex < bank.length && updatedAnswers.length < updatedGame.totalQuestions) {
      _positions[gameId] = nextIndex;
      return bank[nextIndex];
    }

    // Termina el tracking si no hay más preguntas
    _positions.remove(gameId);
    return null;
  }

  int _getPointsForQuestion(String questionId) {
    // Busca la pregunta en el banco y devuelve su valor de puntos (fallback 0)
    for (final entry in _questionBank.values) {
      for (final q in entry) {
        if (q['questionId'] == questionId) return q['points'] as int? ?? 0;
      }
    }
    return 0;
  }

  int _getTimeLimitForQuestion(String questionId) {
    for (final entry in _questionBank.values) {
      for (final q in entry) {
        if (q['questionId'] == questionId) return q['timeLimit'] as int? ?? 0;
      }
    }
    return 0;
  }

  @override
  Future<QuestionResult> submitAnswer(String gameId, String questionId, PlayerAnswer playerAnswer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // En el mock, evalúa y persiste usando el helper definido arriba
    submitAnswerAndGetNextPayload(gameId, questionId, playerAnswer);
    // Devuelve el último QuestionResult almacenado (el que acabamos de persistir)
    final game = _store[gameId];
    if (game == null) throw Exception('Game not found');
    return game.gameAnswers.last;
  }

  @override
  Future<SinglePlayerGame?> getGame(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _store[gameId];
  }

  @override
  Future<SinglePlayerGame> completeGame(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final game = _store[gameId];
    if (game == null) throw Exception('Game not found');

    final completed = SinglePlayerGame(
      gameId: game.gameId,
      quizId: game.quizId,
      totalQuestions: game.totalQuestions,
      playerId: game.playerId,
      gameProgress: GameProgress(state: GameProgressStatus.COMPLETED, progress: 1.0),
      gameScore: game.gameScore,
      startedAt: game.startedAt,
      completedAt: DateTime.now(),
      gameAnswers: game.gameAnswers,
    );

    _store[gameId] = completed;
    return completed;
  }
}
