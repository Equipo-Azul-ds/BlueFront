import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/constants/multiplayer_constants.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';


/// Gestiona el estado de la conexión del socket y eventos del ciclo de vida.
/// Maneja el monitoreo del estado del socket, lógica de reconexión, errores de conexión/sincronización,
/// y eventos del ciclo de vida del anfitrión (salida/retorno). Mantiene el estado de disposición de conexión
/// y cachea datos de error/evento del servidor.
class SessionConnectionManager extends ChangeNotifier {
  SessionConnectionManager({
    required MultiplayerSessionRealtime realtime,
  }) : _realtime = realtime {
    _statusSubscription = _realtime.statusStream.listen((status) {
      _socketStatus = status;
      if (status == MultiplayerSocketStatus.disconnected) {
        _shouldEmitClientReady = true;
      }
      if (status == MultiplayerSocketStatus.connected && _shouldEmitClientReady) {
        _safeEmitClientReady();
      }
      notifyListeners();
    });

    _errorSubscription = _realtime.errors.listen((error) {
      _lastError = error.toString();
      notifyListeners();
    });
  }

  final MultiplayerSessionRealtime _realtime;

  MultiplayerSocketStatus _socketStatus = MultiplayerSocketStatus.idle;
  String? _lastError;
  bool _shouldEmitClientReady = false;

  HostLeftSessionEvent? _hostLeftDto;
  HostReturnedSessionEvent? _hostReturnedDto;
  SyncErrorEvent? _syncErrorDto;
  ConnectionErrorEvent? _connectionErrorDto;
  HostConnectedSuccessEvent? _hostConnectedSuccessDto;
  GameErrorEvent? _gameErrorDto;
  UnavailableSessionEvent? _unavailableSessionDto;

  StreamSubscription<MultiplayerSocketStatus>? _statusSubscription;
  StreamSubscription<Object>? _errorSubscription;
  StreamSubscription<dynamic>? _syncErrorSubscription;
  StreamSubscription<dynamic>? _connectionErrorSubscription;
  StreamSubscription<dynamic>? _hostLeftSubscription;
  StreamSubscription<dynamic>? _hostReturnedSubscription;
  StreamSubscription<dynamic>? _hostConnectedSuccessSubscription;
  StreamSubscription<dynamic>? _gameErrorSubscription;
  StreamSubscription<dynamic>? _unavailableSessionSubscription;

  // Getters
  MultiplayerSocketStatus get socketStatus => _socketStatus;
  String? get lastError => _lastError;
  bool get shouldEmitClientReady => _shouldEmitClientReady;
  HostLeftSessionEvent? get hostLeftDto => _hostLeftDto;
  HostReturnedSessionEvent? get hostReturnedDto => _hostReturnedDto;
  SyncErrorEvent? get syncErrorDto => _syncErrorDto;
  ConnectionErrorEvent? get connectionErrorDto => _connectionErrorDto;
  HostConnectedSuccessEvent? get hostConnectedSuccessDto => _hostConnectedSuccessDto;
  GameErrorEvent? get gameErrorDto => _gameErrorDto;
  UnavailableSessionEvent? get unavailableSessionDto => _unavailableSessionDto;

  /// Registra oyentes para eventos de conexión y ciclo de vida (errores de sincronización, errores de conexión, anfitrión salió/retornó, errores de juego).
  void registerLifecycleListeners(
    void Function(Object error) onEventError,
  ) {
    _syncErrorSubscription?.cancel();
    _syncErrorSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(MultiplayerEvents.syncError)
        .listen(
          (payload) => _handleSyncError(payload, onEventError),
          onError: onEventError,
        );

    _connectionErrorSubscription?.cancel();
    _connectionErrorSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.connectionError)
        .listen(
          (payload) => _handleConnectionError(payload, onEventError),
          onError: onEventError,
        );

    _hostLeftSubscription?.cancel();
    _hostLeftSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.hostLeftSession)
        .listen(
          (payload) => _handleHostLeftSession(payload, onEventError),
          onError: onEventError,
        );

    _hostReturnedSubscription?.cancel();
    _hostReturnedSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.hostReturnedToSession)
        .listen(
          (payload) => _handleHostReturnedSession(payload, onEventError),
          onError: onEventError,
        );

    _hostConnectedSuccessSubscription?.cancel();
    _hostConnectedSuccessSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.hostConnectedSuccess)
        .listen(
          (payload) => _handleHostConnectedSuccess(payload, onEventError),
          onError: onEventError,
        );

    _gameErrorSubscription?.cancel();
    _gameErrorSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(MultiplayerEvents.gameError)
        .listen(
          (payload) => _handleGameError(payload, onEventError),
          onError: onEventError,
        );

    _unavailableSessionSubscription?.cancel();
    _unavailableSessionSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.unavailableSession)
        .listen(
          (payload) => _handleUnavailableSession(payload, onEventError),
          onError: onEventError,
        );
  }
 
   /// Marca la sesión como lista para sincronizar y emite evento client_ready si el socket está conectado.
  void markReadyForSync() {
    _shouldEmitClientReady = true;
    _safeEmitClientReady();
  }

  /// Emite de forma segura client_ready sin perder estado al desconectarse; encola para reintentar en reconexión.
  void _safeEmitClientReady() {
    if (!_realtime.isConnected) {
      return;
    }
    try {
      _realtime.emitClientReady();
      _shouldEmitClientReady = false;
    } catch (error) {
      _lastError = error.toString();
      notifyListeners();
    }
  }

  /// Maneja evento de error de sincronización: cachea error, establece mensaje de error, desconecta socket.
  void _handleSyncError(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = SyncErrorEvent.fromJson(payload);
      print('[EVENT] ✗ RECEIVED: sync_error with message=\"${event.message}\" - DISCONNECTING SOCKET');
      _syncErrorDto = event;
      _lastError = event.message ?? MultiplayerConstants.errorSyncDefault;
      _realtime.disconnect();
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing sync_error: $error');
      onEventError(error);
    }
  }

  /// Maneja evento de error de conexión: cachea error y establece mensaje de error.
  void _handleConnectionError(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = ConnectionErrorEvent.fromJson(payload);
      print('[EVENT] ✗ RECEIVED: connection_error with message=\"${event.message}\"');
      _connectionErrorDto = event;
      _lastError = event.message ?? MultiplayerConstants.errorConnectionDefault;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing connection_error: $error');
      onEventError(error);
    }
  }

  /// Maneja evento de anfitrión salió de la sesión: cachea datos de evento y notifica a oyentes.
  void _handleHostLeftSession(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = HostLeftSessionEvent.fromJson(payload);
      _hostLeftDto = event;
      notifyListeners();
    } catch (error) {
      onEventError(error);
    }
  }

   /// Maneja evento de anfitrión retornó a la sesión: cachea datos de evento y notifica a oyentes.
  void _handleHostReturnedSession(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = HostReturnedSessionEvent.fromJson(payload);
      _hostReturnedDto = event;
      notifyListeners();
    } catch (error) {
      onEventError(error);
    }
  }

  /// Maneja evento de anfitrión conectado exitosamente: cachea datos de evento, limpia errores y notifica a oyentes.
  void _handleHostConnectedSuccess(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = HostConnectedSuccessEvent.fromJson(payload);
      _hostConnectedSuccessDto = event;
      _lastError = null;
      notifyListeners();
    } catch (error) {
      onEventError(error);
    }
  }

  /// Maneja evento de error del juego: cachea error y establece mensaje de error.
  void _handleGameError(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = GameErrorEvent.fromJson(payload);
      _gameErrorDto = event;
      _lastError = event.message;
      notifyListeners();
    } catch (error) {
      onEventError(error);
    }
  }

  /// Maneja evento de sesión no disponible: cachea evento, establece mensaje de error, desconecta socket.
  void _handleUnavailableSession(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = UnavailableSessionEvent.fromJson(payload);
      print('[EVENT] ✗ RECEIVED: unavailable_session with message="${event.message}" - DISCONNECTING SOCKET');
      _unavailableSessionDto = event;
      _lastError = event.message ?? MultiplayerConstants.errorSessionNotFound;
      _realtime.disconnect();
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing unavailable_session: $error');
      onEventError(error);
    }
  }

  /// Limpia el cache de error de sincronización y notifica a oyentes.
  void clearSyncError() {
    _syncErrorDto = null;
    notifyListeners();
  }

  /// Limpia el cache de error de conexión y notifica a oyentes.
  void clearConnectionError() {
    _connectionErrorDto = null;
    notifyListeners();
  }

  /// Limpia el cache de evento de anfitrión salió y notifica a oyentes.
  void clearHostLeftDto() {
    _hostLeftDto = null;
    notifyListeners();
  }

  /// Limpia el cache de evento de anfitrión retornó y notifica a oyentes.
  void clearHostReturnedDto() {
    _hostReturnedDto = null;
    notifyListeners();
  }

  /// Limpia el cache de error del juego y notifica a oyentes.
  void clearGameError() {
    _gameErrorDto = null;
    notifyListeners();
  }

  /// Limpia el cache de evento de sesión no disponible y notifica a oyentes.
  void clearUnavailableSession() {
    _unavailableSessionDto = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    _syncErrorSubscription?.cancel();
    _connectionErrorSubscription?.cancel();
    _hostLeftSubscription?.cancel();
    _hostReturnedSubscription?.cancel();
    _hostConnectedSuccessSubscription?.cancel();
    _gameErrorSubscription?.cancel();
    _unavailableSessionSubscription?.cancel();
    super.dispose();
  }
}
