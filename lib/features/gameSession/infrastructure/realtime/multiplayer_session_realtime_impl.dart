import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import '../socket/multiplayer_socket_client.dart';

/// Adaptador de infraestructura que implementa el puerto realtime delegando en
/// [MultiplayerSocketClient].
class MultiplayerSessionRealtimeImpl implements MultiplayerSessionRealtime {
  MultiplayerSessionRealtimeImpl({required MultiplayerSocketClient socketClient})
      : _socketClient = socketClient;

  final MultiplayerSocketClient _socketClient;

  @override
  /// Abre el socket usando los parámetros de dominio que entrega la capa de
  /// aplicación.
  Future<void> connect(MultiplayerSocketParams params) {
    return _socketClient.connect(params);
  }

  @override
  /// Cierra la conexión del socket.
  Future<void> disconnect() {
    return _socketClient.disconnect();
  }

  @override
  Stream<MultiplayerSocketStatus> get statusStream => _socketClient.statusStream;

  @override
  Stream<Object> get errors => _socketClient.errors;

  @override
  bool get isConnected => _socketClient.isConnected;

  @override
  /// Reenvía eventos del servidor al consumidor con payload tipado.
  Stream<T> listenToServerEvent<T>(String eventName) {
    return _socketClient.listenToEvent<T>(eventName);
  }

  @override
  /// Anuncia que el cliente está listo para recibir eventos tras unirse.
  void emitClientReady() {
    print('[REALTIME] → EMIT: client_ready');
    _socketClient.emit(MultiplayerEvents.clientReady);
  }

  @override
  /// Notifica al servidor que un jugador quiere unirse al lobby.
  void emitPlayerJoin(PlayerJoinPayload payload) {
    print('[REALTIME] → EMIT: player_join with nickname="${payload.nickname}"');
    _socketClient.emit(MultiplayerEvents.playerJoin, payload.toJson());
  }

  @override
  /// Señal del host para iniciar la partida.
  void emitHostStartGame() {
    print('[REALTIME] → EMIT: host_start_game');
    _socketClient.emit(MultiplayerEvents.hostStartGame);
  }

  @override
  /// Envía las respuestas del jugador más el tiempo empleado.
  void emitPlayerSubmitAnswer(PlayerSubmitAnswerPayload payload) {
    print('[REALTIME] → EMIT: player_submit_answer with answers=${payload.answerIds.length}, time=${payload.timeElapsedMs}ms');
    _socketClient.emit(MultiplayerEvents.playerSubmitAnswer, payload.toJson());
  }

  @override
  /// Señal del host para avanzar a la siguiente fase.
  void emitHostNextPhase() {
    print('[REALTIME] → EMIT: host_next_phase');
    _socketClient.emit(MultiplayerEvents.hostNextPhase);
  }

  @override
  /// Señal del host para finalizar la sesión y desconectar jugadores.
  void emitHostEndSession() {
    print('[REALTIME] → EMIT: host_end_session');
    _socketClient.emit(MultiplayerEvents.hostEndSession);
  }
}
