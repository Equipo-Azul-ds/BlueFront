import 'package:flutter/foundation.dart';
import '../../domain/entities/single_player_game.dart';
import '../../application/use_cases/single_player_usecases.dart';

// BLoC usado en la pantalla de resultados. Encapsula la lógica para
// cargar el resumen final de un intento y notificar a la UI de cambios.
class SinglePlayerResultsBloc extends ChangeNotifier {
  final GetSummaryUseCase getSummaryUseCase;

  bool isLoading = false;
  String? error;
  SinglePlayerGame? summaryGame;

  SinglePlayerResultsBloc({required this.getSummaryUseCase});

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void hydrate(SinglePlayerGame? cachedGame) {
    if (cachedGame == null) return;
    summaryGame = cachedGame;
    error = null;
    isLoading = false;
    notifyListeners();
  }

  // Carga el resumen del intento (`gameId`) usando el caso de uso.
  // Maneja estados de carga y errores para que la UI los muestre.
  Future<void> load(String gameId) async {
    _setLoading(true);
    error = null;
    notifyListeners();

    final cached = summaryGame;
    try {
      final res = await getSummaryUseCase.execute(gameId);
      summaryGame = cached == null
          ? res.summaryGame
          : _mergeSummaries(remote: res.summaryGame, cached: cached);
    } catch (e) {
      error = e.toString();
      if (cached == null) {
        summaryGame = null;
      }
    } finally {
      _setLoading(false);
    }
  }

  // Reintenta cargar el resumen (alias para `load`).
  Future<void> retry(String gameId) => load(gameId);

  SinglePlayerGame _mergeSummaries({
    required SinglePlayerGame remote,
    required SinglePlayerGame cached,
  }) {
    if (remote.gameAnswers.isNotEmpty && remote.gameScore.score != 0) {
      return remote;
    }

    final mergedTotalQuestions = remote.totalQuestions != 0
      ? remote.totalQuestions
      : cached.totalQuestions;
    final answers =
      remote.gameAnswers.isNotEmpty ? remote.gameAnswers : cached.gameAnswers;
    final mergedScore = remote.gameScore.score != 0
      ? remote.gameScore
      : cached.gameScore;
    final mergedProgress = remote.gameProgress.progress == 0 &&
            cached.gameProgress.progress != 0
        ? cached.gameProgress
        : remote.gameProgress;
    final mergedTotalCorrect = remote.totalCorrect ??
        cached.totalCorrect ??
        _countCorrectAnswers(answers);
    final mergedAccuracy = remote.accuracyPercentage ??
        cached.accuracyPercentage ??
      _accuracyFromCounts(mergedTotalCorrect, mergedTotalQuestions);

    return SinglePlayerGame(
      gameId: _hasText(remote.gameId) ? remote.gameId : cached.gameId,
      quizId: _hasText(remote.quizId) ? remote.quizId : cached.quizId,
      totalQuestions: mergedTotalQuestions,
      playerId: _hasText(remote.playerId) ? remote.playerId : cached.playerId,
      gameProgress: mergedProgress,
      gameScore: mergedScore,
      startedAt: answers == remote.gameAnswers ? remote.startedAt : cached.startedAt,
      completedAt: remote.completedAt ?? cached.completedAt,
      gameAnswers: answers,
      totalCorrect: mergedTotalCorrect,
      accuracyPercentage: mergedAccuracy,
    );
  }

  bool _hasText(String value) => value.trim().isNotEmpty;

  int _countCorrectAnswers(List<QuestionResult> answers) {
    return answers.where((entry) => entry.evaluatedAnswer.wasCorrect).length;
  }

  double? _accuracyFromCounts(int correctAnswers, int totalQuestions) {
    if (totalQuestions <= 0) return null;
    final ratio = correctAnswers / totalQuestions;
    return (ratio * 100).clamp(0.0, 100.0);
  }
}
