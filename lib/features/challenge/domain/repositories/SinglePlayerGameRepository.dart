import '../entities/SinglePlayerGame.dart';

abstract class SinglePlayerGameRepository {
  Future<SinglePlayerGame> createGame({required String quizId, required String playerId, required int totalQuestions});
  Future<SinglePlayerGame?> getGame(String gameId);
  /// Envía la respuesta de un jugador para [questionId]. El repositorio
  /// devuelve un [QuestionResult] que contiene la evaluación realizada en
  /// el servidor (wasCorrect, pointsEarned). El frontend sólo debe enviar
  /// los índices elegidos por el jugador a través de [playerAnswer].
  Future<QuestionResult> submitAnswer(String gameId, String questionId, PlayerAnswer playerAnswer);
  Future<SinglePlayerGame> completeGame(String gameId);
}
