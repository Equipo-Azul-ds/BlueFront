import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../domain/repositories/multiplayer_session_repository.dart';
import '../datasources/multiplayer_session_remote_data_source.dart';

/// Adaptador de infraestructura que delega en el data source remoto.
class MultiplayerSessionRepositoryImpl implements MultiplayerSessionRepository {
  MultiplayerSessionRepositoryImpl({
    required MultiplayerSessionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final MultiplayerSessionRemoteDataSource _remoteDataSource;

  @override
  /// Crea una nueva sesión multijugador vía REST.
  Future<CreateSessionResponse> createSession(CreateSessionRequest request) {
    return _remoteDataSource.createSession(request);
  }

  @override
  /// Obtiene el PIN de sesión usando un token QR emitido por backend.
  Future<QrTokenLookupResponse> getSessionPinFromQr(String qrToken) {
    return _remoteDataSource.getSessionPinFromQr(qrToken);
  }
}
