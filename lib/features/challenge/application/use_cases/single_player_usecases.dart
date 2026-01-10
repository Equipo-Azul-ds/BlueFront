import '../../domain/entities/single_player_game.dart';
import '../dtos/single_player_dtos.dart';
import '../../domain/repositories/single_player_game_repository.dart';

// Wrappers

// Resultado devuelto por el caso de uso StartAttemptUseCase.
// Contiene el agregado (SinglePlayerGame) y la primera slide a mostrar (si existe).
class StartAttemptResult {
  final SinglePlayerGame game;
  final SlideDTO? firstSlide;

  StartAttemptResult({required this.game, this.firstSlide});
}

// Resultado de consultar el estado actual de un intento (resumen parcial).
// Se usa para resumir la partida y conocer la siguiente slide disponible.
class AttemptStateResult {
  final SinglePlayerGame? game;
  final SlideDTO? nextSlide;

  AttemptStateResult({required this.game, this.nextSlide});
}

// Resultado del envío de una respuesta: incluye la evaluación de la
// pregunta enviada y (opcionalmente) la siguiente slide y el índice
// correcto para mostrar en la UI.
class SubmitAnswerResult {
  final QuestionResult evaluatedQuestion;
  final SlideDTO? nextSlide;
  final int? correctAnswerIndex;
  final SinglePlayerGame? updatedGame;

  SubmitAnswerResult({
    required this.evaluatedQuestion,
    this.nextSlide,
    this.correctAnswerIndex,
    this.updatedGame,
  });
}

// Resultado del caso de uso que devuelve el resumen final del intento.
class SummaryResult {
  final SinglePlayerGame summaryGame;
  SummaryResult({required this.summaryGame});
}

// Use Cases

/// StartAttemptUseCase: Empieza un intento y devuelve el agregado y la primera pregunta a traves de DTO
class StartAttemptUseCase {
  final SinglePlayerGameRepository repository;

  StartAttemptUseCase({required this.repository});

  Future<StartAttemptResult> execute({
    required String kahootId,
  }) async {
    final response = await repository.startAttempt(
      kahootId: kahootId,
    );
    SinglePlayerGame latest = response.game;
    SlideDTO? firstSlide = response.nextSlide;

    return StartAttemptResult(game: latest, firstSlide: firstSlide);
  }
}

/// GetAttemptStateUseCase: Busca el ultimo estado del Quiz para resumir la partida
class GetAttemptStateUseCase {
  final SinglePlayerGameRepository repository;
  GetAttemptStateUseCase({required this.repository});

  Future<AttemptStateResult> execute(String attemptId) async {
    final response = await repository.getAttemptState(attemptId);
    return AttemptStateResult(
      game: response.game,
      nextSlide: response.nextSlide,
    );
  }
}

/// SubmitAnswerUseCase: Envia la respuesta para ser evaluada por el backend y retorna el DTO
/// De la siguiente pregunta (Slide)
class SubmitAnswerUseCase {
  final SinglePlayerGameRepository repository;

  SubmitAnswerUseCase({required this.repository});

  Future<SubmitAnswerResult> execute(
    String attemptId,
    PlayerAnswer playerAnswer,
  ) async {
    final response = await repository.submitAnswer(attemptId, playerAnswer);
    return SubmitAnswerResult(
      evaluatedQuestion: response.evaluatedQuestion,
      nextSlide: response.nextSlide,
      correctAnswerIndex: response.correctAnswerIndex,
      updatedGame: response.updatedGame,
    );
  }
}

/// GetSummaryUseCase: Obtiene el estado final del quiz para el resultado
class GetSummaryUseCase {
  final SinglePlayerGameRepository repository;
  GetSummaryUseCase(this.repository);

  Future<SummaryResult> execute(String attemptId) async {
    final game = await repository.getAttemptSummary(attemptId);
    return SummaryResult(summaryGame: game);
  }
}
