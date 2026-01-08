import '../../application/dtos/multiplayer_session_dtos.dart';

/// Puerto HTTP para sesiones multijugador.
abstract class MultiplayerSessionRepository {
  Future<CreateSessionResponse> createSession(CreateSessionRequest request);

  Future<QrTokenLookupResponse> getSessionPinFromQr(String qrToken);
}
