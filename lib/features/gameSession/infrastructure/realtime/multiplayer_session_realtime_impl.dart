import '../../application/dtos/multiplayer_session_dtos.dart';
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
    _socketClient.emit('client_ready');
  }

  @override
  /// Notifica al servidor que un jugador quiere unirse al lobby.
  void emitPlayerJoin(PlayerJoinPayload payload) {
    _socketClient.emit('player_join', payload.toJson());
  }

  @override
  /// Señal del host para iniciar la partida.
  void emitHostStartGame() {
    _socketClient.emit('host_start_game');
  }

  @override
  /// Envía las respuestas del jugador más el tiempo empleado.
  void emitPlayerSubmitAnswer(PlayerSubmitAnswerPayload payload) {
    _socketClient.emit('player_submit_answer', payload.toJson());
  }

  @override
  /// Señal del host para avanzar a la siguiente fase.
  void emitHostNextPhase() {
    _socketClient.emit('host_next_phase');
  }

  @override
  /// Señal del host para finalizar la sesión y desconectar jugadores.
  void emitHostEndSession() {
    _socketClient.emit('host_end_session');
  }
}
