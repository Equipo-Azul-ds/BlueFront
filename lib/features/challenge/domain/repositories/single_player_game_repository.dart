import '../entities/single_player_game.dart';

abstract class SinglePlayerGameRepository {
  // H5.1: Crea o reanuda un intento para un jugador en un quiz concreto.
  Future<SinglePlayerGame> startAttempt({
    required String kahootId,
    required String playerId,
    required int totalQuestions,
  });

  // H5.2: Persiste la respuesta del jugador y devuelve la evaluación de la
  // pregunta (QuestionResult).
  Future<QuestionResult> submitAnswer(
    String attemptId,
    PlayerAnswer playerAnswer,
  );

  // H5.3: Recupera el estado actual del intento (puede devolver null si no existe).
  Future<SinglePlayerGame?> getAttemptState(String attemptId);

  // H5.4: Obtiene el resumen final del intento (puntos, respuestas, etc.).
  Future<SinglePlayerGame> getAttemptSummary(String attemptId);
}
