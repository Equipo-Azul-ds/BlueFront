import '../entities/single_player_game.dart';

abstract class SinglePlayerGameRepository {
  Future<SinglePlayerGame> startAttempt({required String kahootId,required String playerId,required int totalQuestions,});
  Future<SinglePlayerGame?> getAttemptState(String attemptId);
  Future<QuestionResult> submitAnswer(String attemptId,PlayerAnswer playerAnswer,);
  Future<SinglePlayerGame> getAttemptSummary(String attemptId);
}
