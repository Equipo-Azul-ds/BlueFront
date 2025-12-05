import '../../domain/entities/single_player_game.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../dtos/single_player_dtos.dart';
import '../ports/slide_provider.dart';

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

  SubmitAnswerResult({
    required this.evaluatedQuestion,
    this.nextSlide,
    this.correctAnswerIndex,
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
  final SlideProvider slideProvider;
  final GetAttemptStateUseCase? getAttemptStateUseCase;

  StartAttemptUseCase({
    required this.repository,
    required this.slideProvider,
    this.getAttemptStateUseCase,
  });

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

    // Intentamos obtener el estado más reciente del intento mediante
    // `GetAttemptStateUseCase` cuando esté disponible. De esta forma la
    // capa de aplicación usa explícitamente el caso de uso de consulta para
    // reanudar en lugar de depender únicamente del comportamiento de
    // `startAttempt`.
    SinglePlayerGame latest = game;
    if (getAttemptStateUseCase != null) {
      try {
        final state = await getAttemptStateUseCase!.execute(game.gameId);
        if (state.game != null) {
          latest = state.game!;
        }
      } catch (_) {
        // Si falla la consulta de estado, continuamos con la respuesta de
        // `startAttempt` para no bloquear el inicio.
      }
    }

    // Sincronizamos el puntero del proveedor de slides con el número de
    // respuestas persistidas en el agregado para evitar avances dobles.
    await slideProvider.ensurePointerSynced(
      latest.gameId,
      latest.gameAnswers.length,
    );
    final firstSlide = await slideProvider.getNextSlideDto(latest.gameId);

    return StartAttemptResult(game: latest, firstSlide: firstSlide);
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
