import 'package:flutter/foundation.dart';
import '../../application/use_cases/single_player_usecases.dart';
import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';
import '../../infrastructure/storage/single_player_attempt_tracker.dart';

// BLoC que expone el estado para la pantalla de desafío en modo un jugador.
// Orquesta los casos de uso: iniciar intento, enviar respuestas y obtener
// resúmenes. La UI se subscribe a este ChangeNotifier para actualizarse.
class SinglePlayerChallengeBloc extends ChangeNotifier {
  final StartAttemptUseCase startAttemptUseCase;
  final SubmitAnswerUseCase submitAnswerUseCase;
  final GetSummaryUseCase getSummaryUseCase;
  final SinglePlayerAttemptTracker attemptTracker;

  SinglePlayerChallengeBloc({
    required this.startAttemptUseCase,
    required this.submitAnswerUseCase,
    required this.getSummaryUseCase,
    required this.attemptTracker,
  });

  bool isLoading = false;
  SinglePlayerGame? currentGame;
  SlideDTO? currentSlide;
  QuestionResult? lastResult;
  int? lastCorrectIndex;
  SinglePlayerGame? finalSummary;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Inicia o reanuda un intento: llama al caso de uso que crea/recupera el
  // agregado y obtiene la primera slide (si existe).
  Future<void> startGame(String kahootId) async {
    _setLoading(true);
    try {
      final result = await startAttemptUseCase.execute(
        kahootId: kahootId,
      );

      _applyGameState(result.game, result.firstSlide);
      await attemptTracker.saveAttemptId(result.game.quizId, result.game.gameId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> hydrateExistingGame(
    SinglePlayerGame game, {
    SlideDTO? nextSlide,
  }) async {
    _applyGameState(game, nextSlide);
    await attemptTracker.saveAttemptId(game.quizId, game.gameId);
    notifyListeners();
  }

  // Envía la respuesta del jugador al caso de uso. Actualiza el estado
  // local con la evaluación y refresca el agregado consultando el estado
  // del intento para mantener coherencia.
  Future<void> submitAnswer(PlayerAnswer answer) async {
    if (currentGame == null) return;
    _setLoading(true);
    try {
      final result = await submitAnswerUseCase.execute(
        currentGame!.gameId,
        answer,
      );

      lastResult = result.evaluatedQuestion;
      lastCorrectIndex = result.correctAnswerIndex;
      currentSlide = result.nextSlide;
      final baseGame = result.updatedGame ?? currentGame!;
      currentGame = _mergeAnswerIntoGame(
        baseGame,
        result.evaluatedQuestion,
        trustBaseScore: result.updatedGame != null,
      );
      await _syncAttemptTracking();
    } finally {
      _setLoading(false);
    }
  }

  // Solicita el resumen final del intento (puntos, respuestas, etc.).
  Future<void> finishGame() async {
    if (currentGame == null) return;
    _setLoading(true);

    final result = await getSummaryUseCase.execute(currentGame!.gameId);
    finalSummary = result.summaryGame;
    await attemptTracker.clearAttempt(currentGame!.quizId);

    _setLoading(false);
  }

  void _applyGameState(SinglePlayerGame game, SlideDTO? slide) {
    currentGame = game;
    currentSlide = slide;
    lastResult = null;
    lastCorrectIndex = null;
    finalSummary = null;
  }

  SinglePlayerGame _mergeAnswerIntoGame(
    SinglePlayerGame base,
    QuestionResult answer, {
    required bool trustBaseScore,
  }) {
    final updatedAnswers = List<QuestionResult>.from(base.gameAnswers);
    final existingIndex =
        updatedAnswers.indexWhere((entry) => entry.questionId == answer.questionId);
    final bool replacingExisting = existingIndex >= 0;
    if (replacingExisting) {
      updatedAnswers[existingIndex] = answer;
    } else {
      updatedAnswers.add(answer);
    }

    final newScore = (trustBaseScore || replacingExisting)
        ? base.gameScore.score
        : base.gameScore.score + answer.evaluatedAnswer.pointsEarned;
    final totalQuestions = base.totalQuestions;
    final answered = updatedAnswers.length;
    final completed = totalQuestions > 0 && answered >= totalQuestions;
    final correctAnswers =
        updatedAnswers.where((entry) => entry.evaluatedAnswer.wasCorrect).length;
    final progress = totalQuestions == 0
      ? base.gameProgress.progress
      : (answered / totalQuestions).clamp(0.0, 1.0).toDouble();
    final nextState =
        completed ? GameProgressStatus.COMPLETED : base.gameProgress.state;

    return SinglePlayerGame(
      gameId: base.gameId,
      quizId: base.quizId,
      totalQuestions: totalQuestions,
      playerId: base.playerId,
      gameProgress: GameProgress(state: nextState, progress: progress),
      gameScore: GameScore(score: newScore),
      startedAt: base.startedAt,
      completedAt: completed ? (base.completedAt ?? DateTime.now()) : base.completedAt,
      gameAnswers: updatedAnswers,
      totalCorrect: correctAnswers,
      accuracyPercentage: _accuracyFromCounts(correctAnswers, totalQuestions) ??
          base.accuracyPercentage,
    );
  }

  double? _accuracyFromCounts(int correctAnswers, int totalQuestions) {
    if (totalQuestions <= 0) return null;
    final ratio = correctAnswers / totalQuestions;
    return (ratio * 100).clamp(0.0, 100.0);
  }

  Future<void> _syncAttemptTracking() async {
    final game = currentGame;
    if (game == null) return;
    if (game.gameProgress.state == GameProgressStatus.COMPLETED) {
      await attemptTracker.clearAttempt(game.quizId);
    } else {
      await attemptTracker.saveAttemptId(game.quizId, game.gameId);
    }
  }
}
