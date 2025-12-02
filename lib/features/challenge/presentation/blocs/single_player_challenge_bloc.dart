import 'package:flutter/foundation.dart';
import '../../application/use_cases/single_player_usecases.dart';
import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';

class SinglePlayerChallengeBloc extends ChangeNotifier {
  final StartAttemptUseCase startAttemptUseCase;
  final GetAttemptStateUseCase getAttemptStateUseCase;
  final SubmitAnswerUseCase submitAnswerUseCase;
  final GetSummaryUseCase getSummaryUseCase;

  SinglePlayerChallengeBloc({
    required this.startAttemptUseCase,
    required this.getAttemptStateUseCase,
    required this.submitAnswerUseCase,
    required this.getSummaryUseCase,
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

  Future<void> startGame(
    String kahootId,
    String playerId,
    int totalQuestions,
  ) async {
    _setLoading(true);

    final result = await startAttemptUseCase.execute(
      kahootId: kahootId,
      playerId: playerId,
      totalQuestions: totalQuestions,
    );

    currentGame = result.game;
    currentSlide = result.firstSlide;

    _setLoading(false);
  }

  Future<void> submitAnswer(PlayerAnswer answer) async {
    if (currentGame == null) return;
    _setLoading(true);

    final result = await submitAnswerUseCase.execute(
      currentGame!.gameId,
      answer,
    );

    lastResult = result.evaluatedQuestion;
    lastCorrectIndex = result.correctAnswerIndex;
    currentSlide = result.nextSlide;

    final stateResult = await getAttemptStateUseCase.execute(
      currentGame!.gameId,
    );
    currentGame = stateResult.game;
    currentSlide = stateResult.nextSlide ?? currentSlide;

    _setLoading(false);
  }

  Future<void> finishGame() async {
    if (currentGame == null) return;
    _setLoading(true);

    final result = await getSummaryUseCase.execute(currentGame!.gameId);
    finalSummary = result.summaryGame;

    _setLoading(false);
  }
}
