import 'dart:async';
import '../../domain/entities/single_player_game.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../../application/ports/slide_provider.dart';
import '../../application/dtos/single_player_dtos.dart';

class SinglePlayerGameRepositoryImpl
    implements SinglePlayerGameRepository, SlideProvider {
  final Map<String, SinglePlayerGame> _games = {};
  final Map<String, int> _questionPosition =
      {};

  // Mock question bank para Slides DTO
  final List<SlideDTO> _mockSlides = [
    SlideDTO(
      slideId: 'q1',
      questionText: 'What is 2 + 2?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: '3'),
        SlideOptionDTO(index: 1, text: '4'),
        SlideOptionDTO(index: 2, text: '5'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q2',
      questionText: 'What is the capital of France?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: 'Paris'),
        SlideOptionDTO(index: 1, text: 'London'),
        SlideOptionDTO(index: 2, text: 'Berlin'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q3',
      questionText: 'Which planet is known as the Red Planet?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: 'Earth'),
        SlideOptionDTO(index: 1, text: 'Mars'),
        SlideOptionDTO(index: 2, text: 'Venus'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q4',
      questionText: 'What is the boiling point of water (°C)?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: '90'),
        SlideOptionDTO(index: 1, text: '100'),
        SlideOptionDTO(index: 2, text: '110'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q5',
      questionText: 'Which language is primary for Flutter development?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: 'Java'),
        SlideOptionDTO(index: 1, text: 'Dart'),
        SlideOptionDTO(index: 2, text: 'Kotlin'),
      ],
      mediaUrl: null,
    ),
  ];

  // Index que tiene el back para determinar la respuesta correcta
  final Map<String, int> _correctAnswers = {
    'q1': 1,
    'q2': 0,
    'q3': 1,
    'q4': 1,
    'q5': 1,
  };

  @override
  Future<SinglePlayerGame> startAttempt({
    required String kahootId,
    required String playerId,
    required int totalQuestions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final now = DateTime.now();
    // Si hay un intento en progreso existente para este jugador+quiz, preferimos
    // el más reciente (por startedAt) y lo reanudamos. Esto evita que
    // un orden arbitrario nos haga reanudar un intento más antiguo.
    SinglePlayerGame? existing;
    for (final g in _games.values) {
      if (g.playerId == playerId &&
          g.quizId == kahootId &&
          g.gameProgress.state == GameProgressStatus.IN_PROGRESS) {
        if (existing == null || g.startedAt.isAfter(existing.startedAt)) {
          existing = g;
        }
      }
    }

    if (existing != null) {
      // Reanuda intento existente
      final resumeId = existing.gameId;
      final expectedIdx = existing.gameAnswers.length;
      final currentPtr = _questionPosition[resumeId] ?? 0;
      if (currentPtr != expectedIdx) {
        _questionPosition[resumeId] = expectedIdx;

      }
      return existing;
    }

    final attemptId = 'attempt_${now.millisecondsSinceEpoch}';

    final game = SinglePlayerGame(
      gameId: attemptId,
      quizId: kahootId,
      totalQuestions: totalQuestions,
      playerId: playerId,
      gameProgress: GameProgress(
        state: GameProgressStatus.IN_PROGRESS,
        progress: 0.0,
      ),
      gameScore: GameScore(score: 0),
      startedAt: now,
      completedAt: null,
      gameAnswers: [],
    );

    _games[attemptId] = game;
    _questionPosition[attemptId] = 0;

    return game;
  }

  @override
  Future<SinglePlayerGame?> getAttemptState(String attemptId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _games[attemptId];
  }

  @override
  Future<QuestionResult> submitAnswer(
    String attemptId,
    PlayerAnswer playerAnswer,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final game = _games[attemptId];
    if (game == null) throw Exception('Attempt not found');

    // Determina qué pregunta fue la última servida a este intento.
    // Usamos _questionPosition como el puntero "siguiente a servir", por lo que la pregunta actual que fue respondida es _questionPosition[attemptId] - 1.
    final nextPos = _questionPosition[attemptId] ?? 0;
    final currentQuestionIndex = (nextPos - 1) >= 0 ? (nextPos - 1) : 0;

    // Si el dominio no lleva explícitamente los IDs de slide/pregunta,
    // leemos questionId de la lista mock de slides (solo en infraestructura).
    final slide = (currentQuestionIndex < _mockSlides.length)
        ? _mockSlides[currentQuestionIndex]
        : null;
    final questionId =
        slide?.slideId ?? 'unknown_question_$currentQuestionIndex';

    // Calcula corrección usando la clave de respuestas de infra y el índice de respuesta del jugador.
    final chosenIndex =
        (playerAnswer.answerIndex == null || playerAnswer.answerIndex!.isEmpty)
        ? null
        : playerAnswer.answerIndex!.first;
    final correctIndex = _correctAnswers[questionId];
    final wasCorrect =
        (chosenIndex != null &&
        correctIndex != null &&
        chosenIndex == correctIndex);

    // Calcula puntos basados en corrección y tiempo usado
    final int baseMax = 1000;
    final int baseMin = 200;
    final int timeUsed = playerAnswer.timeUsedMs;
    final int totalMs = (slide?.timeLimitSeconds ?? 20) * 1000;
    int pointsEarned = 0;
    if (wasCorrect) {
      final double frac = totalMs > 0 ? (timeUsed / totalMs) : 1.0;
      final double clamped = frac.clamp(0.0, 1.0);
      final double score = (1.0 - clamped) * (baseMax - baseMin) + baseMin;
      pointsEarned = score.round();
    } else {
      pointsEarned = 0;
    }

    // Construye EvaluatedAnswer y QuestionResult
    final evaluated = EvaluatedAnswer(
      wasCorrect: wasCorrect,
      pointsEarned: pointsEarned,
    );
    final qr = QuestionResult(
      questionId: questionId,
      playerAnswer: playerAnswer,
      evaluatedAnswer: evaluated,
    );

    // Persiste el agregado en dominio (crea los value objects actualizados)
    final updatedAnswers = List<QuestionResult>.from(game.gameAnswers)..add(qr);
    final updatedScore = game.gameScore.score + evaluated.pointsEarned;
    final progress =
        updatedAnswers.length /
        (game.totalQuestions == 0 ? 1 : game.totalQuestions);
    final updatedProgressObj = GameProgress(
      state: progress >= 1.0
          ? GameProgressStatus.COMPLETED
          : GameProgressStatus.IN_PROGRESS,
      progress: progress,
    );
    final updatedScoreObj = GameScore(score: updatedScore);

    final updatedGame = SinglePlayerGame(
      gameId: game.gameId,
      quizId: game.quizId,
      totalQuestions: game.totalQuestions,
      playerId: game.playerId,
      gameProgress: updatedProgressObj,
      gameScore: updatedScoreObj,
      startedAt: game.startedAt,
      completedAt: progress >= 1.0 ? DateTime.now() : null,
      gameAnswers: updatedAnswers,
    );

    _games[attemptId] = updatedGame;


    return qr;
  }

  @override
  Future<SinglePlayerGame> getAttemptSummary(String attemptId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final game = _games[attemptId];
    if (game == null) throw Exception('Attempt not found');
    return game;
  }

  // SlideProvider

  @override
  Future<SlideDTO?> getNextSlideDto(String attemptId) async {
    final idx = _questionPosition[attemptId] ?? 0;
    if (idx >= _mockSlides.length) {
      // No hay mas Slides
      return null;
    }

    final slide = _mockSlides[idx];
    _questionPosition[attemptId] = idx + 1;
    // Devuelve Slide
    return slide;
  }

  @override
  Future<int?> getCorrectAnswerIndex(
    String attemptId,
    String questionId,
  ) async {
    return _correctAnswers[questionId];
  }

  /// Para Rematch
  Future<SinglePlayerGame> createFreshAttempt({
    required String kahootId,
    required String playerId,
    required int totalQuestions,
  }) async {
    final now = DateTime.now();
    final attemptId = 'attempt_${now.millisecondsSinceEpoch}';

    final game = SinglePlayerGame(
      gameId: attemptId,
      quizId: kahootId,
      totalQuestions: totalQuestions,
      playerId: playerId,
      gameProgress: GameProgress(
        state: GameProgressStatus.IN_PROGRESS,
        progress: 0.0,
      ),
      gameScore: GameScore(score: 0),
      startedAt: now,
      completedAt: null,
      gameAnswers: [],
    );

    _games[attemptId] = game;
    _questionPosition[attemptId] = 0;

    return game;
  }
}
