import '../../application/dtos/multiplayer_session_dtos.dart';

/// Puerto realtime (socket) para sesiones multijugador.
abstract class MultiplayerSessionRealtime {
  Future<void> connect(MultiplayerSocketParams params);

  Future<void> disconnect();

  Stream<MultiplayerSocketStatus> get statusStream;

  Stream<Object> get errors;

  bool get isConnected;

  Stream<T> listenToServerEvent<T>(String eventName);

  void emitClientReady();

  void emitPlayerJoin(PlayerJoinPayload payload);

  void emitHostStartGame();

  void emitPlayerSubmitAnswer(PlayerSubmitAnswerPayload payload);

  void emitHostNextPhase();

  void emitHostEndSession();
}

typedef MultiplayerJwtProvider = Future<String?> Function();

enum MultiplayerRole { host, player }

extension MultiplayerRoleHeader on MultiplayerRole {
  String toHeaderValue() => name.toUpperCase();
}

enum MultiplayerSocketStatus { idle, connecting, connected, disconnected, error }

class MultiplayerSocketParams {
  MultiplayerSocketParams({
    required this.pin,
    required this.role,
    this.jwt,
  });

  final String pin;
  final MultiplayerRole role;
  final String? jwt;
}
