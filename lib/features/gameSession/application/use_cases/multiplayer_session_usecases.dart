import '../dtos/multiplayer_session_dtos.dart';
import '../../infrastructure/datasources/multiplayer_session_remote_data_source.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';

/// Crea la sesión (REST) y conecta socket como host.
class InitializeHostLobbyUseCase {
  InitializeHostLobbyUseCase({
    required this.dataSource,
    required this.realtime,
  });

  final MultiplayerSessionRemoteDataSource dataSource;
  final MultiplayerSessionRealtime realtime;

  Future<CreateSessionResponse> execute({
    required String kahootId,
    String? jwt,
  }) async {
    final session = await dataSource.createSession(
      CreateSessionRequest(kahootId: kahootId),
    );
    await realtime.connect(
      MultiplayerSocketParams(
        pin: session.sessionPin,
        role: MultiplayerRole.host,
        jwt: jwt,
      ),
    );
    return session;
  }
}

/// Resuelve PIN a partir de token QR provisto por backend.
class ResolvePinFromQrTokenUseCase {
  ResolvePinFromQrTokenUseCase({required this.dataSource});

  final MultiplayerSessionRemoteDataSource dataSource;

  Future<String> execute(String qrToken) async {
    final response = await dataSource.getSessionPinFromQr(qrToken);
    return response.sessionPin;
  }
}

/// Conecta socket como jugador al lobby indicado por PIN.
class JoinLobbyUseCase {
  JoinLobbyUseCase({
    required this.realtime,
  });

  final MultiplayerSessionRealtime realtime;

  Future<void> execute({
    required String pin,
    String? jwt,
  }) async {
    await realtime.connect(
      MultiplayerSocketParams(
        pin: pin,
        role: MultiplayerRole.player,
        jwt: jwt,
      ),
    );
  }
}

/// Desconecta del socket y limpia sesión remota.
class LeaveSessionUseCase {
  LeaveSessionUseCase({required this.realtime});

  final MultiplayerSessionRealtime realtime;

  Future<void> execute() {
    return realtime.disconnect();
  }
}

/// Emite evento para iniciar la partida (host).
class EmitHostStartGameUseCase {
  EmitHostStartGameUseCase({required this.realtime});

  final MultiplayerSessionRealtime realtime;

  void execute() => realtime.emitHostStartGame();
}

/// Emite evento para avanzar de fase (host).
class EmitHostNextPhaseUseCase {
  EmitHostNextPhaseUseCase({required this.realtime});

  final MultiplayerSessionRealtime realtime;

  void execute() => realtime.emitHostNextPhase();
}

/// Emite evento para finalizar la sesión (host).
class EmitHostEndSessionUseCase {
  EmitHostEndSessionUseCase({required this.realtime});

  final MultiplayerSessionRealtime realtime;

  void execute() => realtime.emitHostEndSession();
}

/// Emite respuesta del jugador con tiempos y selección.
class SubmitPlayerAnswerUseCase {
  SubmitPlayerAnswerUseCase({required this.realtime});

  final MultiplayerSessionRealtime realtime;

  void execute({
    required String questionId,
    required List<String> answerIds,
    required int timeElapsedMs,
  }) {
    realtime.emitPlayerSubmitAnswer(
      PlayerSubmitAnswerPayload(
        questionId: questionId,
        answerIds: answerIds,
        timeElapsedMs: timeElapsedMs,
      ),
    );
  }
}
