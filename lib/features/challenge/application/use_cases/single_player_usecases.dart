import '../../domain/entities/single_player_game.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../dtos/single_player_dtos.dart';
import '../ports/slide_provider.dart';

// Wrappers

class StartAttemptResult {
  final SinglePlayerGame game;
  final SlideDTO? firstSlide;

  StartAttemptResult({required this.game, this.firstSlide});
}

class AttemptStateResult {
  final SinglePlayerGame? game;
  final SlideDTO? nextSlide;

  AttemptStateResult({required this.game, this.nextSlide});
}

class SubmitAnswerResult {
  final QuestionResult evaluatedQuestion;
  final SlideDTO? nextSlide;
  final int? correctAnswerIndex;

  SubmitAnswerResult({
    required this.evaluatedQuestion,
    this.nextSlide,
    this.correctAnswerIndex,
  });
}

class SummaryResult {
  final SinglePlayerGame summaryGame;
  SummaryResult({required this.summaryGame});
}

// Use Cases

/// StartAttemptUseCase: Empieza un intento y devuelve el agregado y la primera pregunta a traves de DTO
class StartAttemptUseCase {
  final SinglePlayerGameRepository repository;
  final SlideProvider slideProvider;

  StartAttemptUseCase({required this.repository, required this.slideProvider});

  Future<StartAttemptResult> execute({
    required String kahootId,
    required String playerId,
    required int totalQuestions,
  }) async {
    final game = await repository.startAttempt(
      kahootId: kahootId,
      playerId: playerId,
      totalQuestions: totalQuestions,
    );
    final firstSlide = await slideProvider.getNextSlideDto(game.gameId);

    return StartAttemptResult(game: game, firstSlide: firstSlide);
  }
}

/// GetAttemptStateUseCase: Busca el ultimo estado del Quiz para resumir la partida
class GetAttemptStateUseCase {
  final SinglePlayerGameRepository repository;
  GetAttemptStateUseCase({required this.repository});

  Future<AttemptStateResult> execute(String attemptId) async {
    final game = await repository.getAttemptState(attemptId);
    return AttemptStateResult(game: game, nextSlide: null);
  }
}

/// SubmitAnswerUseCase: Envia la respuesta para ser evaluada por el backend y retorna el DTO
/// De la siguiente pregunta (Slide)
class SubmitAnswerUseCase {
  final SinglePlayerGameRepository repository;
  final SlideProvider slideProvider;
  SubmitAnswerUseCase({required this.repository, required this.slideProvider});

  Future<SubmitAnswerResult> execute(
    String attemptId,
    PlayerAnswer playerAnswer,
  ) async {
    final evaluated = await repository.submitAnswer(attemptId, playerAnswer);
    final nextSlide = await slideProvider.getNextSlideDto(attemptId);
    final correctIndex = await slideProvider.getCorrectAnswerIndex(
      attemptId,
      evaluated.questionId,
    );
    return SubmitAnswerResult(
      evaluatedQuestion: evaluated,
      nextSlide: nextSlide,
      correctAnswerIndex: correctIndex,
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
