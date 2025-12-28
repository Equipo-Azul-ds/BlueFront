import '../entities/single_player_game.dart';
import '../../application/dtos/single_player_dtos.dart';

class StartAttemptRepositoryResponse {
  final SinglePlayerGame game;
  final SlideDTO? nextSlide;

  StartAttemptRepositoryResponse({required this.game, this.nextSlide});
}

class AttemptStateRepositoryResponse {
  final SinglePlayerGame? game;
  final SlideDTO? nextSlide;
  final int? correctAnswerIndex;

  AttemptStateRepositoryResponse({
    required this.game,
    this.nextSlide,
    this.correctAnswerIndex,
  });
}

class SubmitAnswerRepositoryResponse {
  final QuestionResult evaluatedQuestion;
  final SlideDTO? nextSlide;
  final int? correctAnswerIndex;
  final SinglePlayerGame? updatedGame;

  SubmitAnswerRepositoryResponse({
    required this.evaluatedQuestion,
    this.nextSlide,
    this.correctAnswerIndex,
    this.updatedGame,
  });
}

abstract class SinglePlayerGameRepository {
  Future<StartAttemptRepositoryResponse> startAttempt({
    required String kahootId,
  });

  Future<SubmitAnswerRepositoryResponse> submitAnswer(
    String attemptId,
    PlayerAnswer playerAnswer,
  );

  Future<AttemptStateRepositoryResponse> getAttemptState(String attemptId);

  Future<SinglePlayerGame> getAttemptSummary(String attemptId);
}
