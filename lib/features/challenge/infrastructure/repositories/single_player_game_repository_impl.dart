import 'dart:async';
import '../../domain/entities/single_player_game.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../../application/ports/slide_provider.dart';

class SinglePlayerGameRepositoryImpl implements SinglePlayerGameRepository {
  // Repositorio en memoria que guarda los intentos de juego. Se encarga de
  // crear, reanudar y persistir respuestas dentro del agregado
  // `SinglePlayerGame`.
  final Map<String, SinglePlayerGame> _games = {};
  // Puntero interno que indica la "próxima" pregunta a servir por este
  // repositorio. 
  final SlideProvider slideProvider;

  SinglePlayerGameRepositoryImpl({required this.slideProvider});

  @override
  Future<SinglePlayerGame> startAttempt({
    required String kahootId,
    required String playerId,
    required int totalQuestions,
  }) async {
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
      // Reanuda intento existente: devolvemos el agregado tal cual está.
      return existing;
    }

    final attemptId = '${kahootId}_attempt_${now.millisecondsSinceEpoch}';

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

    return game;
  }

  @override
  Future<SinglePlayerGame?> getAttemptState(String attemptId) async {
    // getAttemptState: devuelve el agregado `SinglePlayerGame` tal como
    // está persistido en memoria. El método se usa para recuperar el estado
    // actual del intento (p. ej. para reanudar una partida) y para refrescar
    // el agregado después de enviar una respuesta.
    return _games[attemptId];
  }

  @override
  Future<QuestionResult> submitAnswer(
    String attemptId,
    PlayerAnswer playerAnswer,
  ) async {
    final game = _games[attemptId];
    if (game == null) throw Exception('Attempt not found');

    // Determina el índice de la pregunta que está siendo respondida usando
    // el número de respuestas ya persistidas: si `game.gameAnswers.length`
    // es N significa que el jugador está respondiendo la slide en el índice
    // `N` (0-based).
    final currentQuestionIndex = game.gameAnswers.length;

    // Obtenemos metadata de la slide desde el SlideProvider sin avanzar el
    // puntero (peek). Esto evita duplicar el banco de slides dentro del
    // repositorio.
    final slide = await slideProvider.peekSlideDto(
      attemptId,
      currentQuestionIndex,
    );
    final questionId =
        slide?.slideId ?? 'unknown_question_$currentQuestionIndex';

    // Calcula corrección usando la clave de respuestas de infra y el índice de respuesta del jugador.
    final chosenIndex =
        (playerAnswer.answerIndex == null || playerAnswer.answerIndex!.isEmpty)
        ? null
        : playerAnswer.answerIndex!.first;
    final correctIndex = await slideProvider.getCorrectAnswerIndex(
      attemptId,
      questionId,
    );
    final wasCorrect =
        (chosenIndex != null &&
        correctIndex != null &&
        chosenIndex == correctIndex);

    // Calcula puntos basados en corrección y tiempo usado. Las respuestas
    // correctas obtienen un puntaje entre `baseMin` y `baseMax` proporcional
    // a la rapidez con la que se respondió.
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

    // Persiste el agregado en dominio (se crea una copia inmutable con los
    // valores actualizados: respuestas, progresión y score).
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
    final game = _games[attemptId];
    if (game == null) throw Exception('Attempt not found');
    return game;
  }

}
