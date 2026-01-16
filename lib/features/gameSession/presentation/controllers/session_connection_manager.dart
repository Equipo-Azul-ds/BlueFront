import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/constants/multiplayer_constants.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import 'base_session_manager.dart';

/// Gestiona el estado de la conexión del socket y eventos del ciclo de vida.
/// Maneja el monitoreo del estado del socket, lógica de reconexión, errores de conexión/sincronización,
/// y eventos del ciclo de vida del anfitrión (salida/retorno). Mantiene el estado de disposición de conexión
/// y cachea datos de error/evento del servidor.
class SessionConnectionManager extends BaseSessionManager {
  SessionConnectionManager({
    required MultiplayerSessionRealtime realtime,
  }) : super(realtime: realtime) {
    statusSubscription = realtime.statusStream.listen((status) {
      _socketStatus = status;
      if (status == MultiplayerSocketStatus.disconnected) {
        _shouldEmitClientReady = true;
      }
      if (status == MultiplayerSocketStatus.connected && _shouldEmitClientReady) {
        _safeEmitClientReady();
      }
      notifyListeners();
    });

    errorSubscription = realtime.errors.listen((error) {
      _lastError = error.toString();
      notifyListeners();
    });
  }

  late final StreamSubscription<MultiplayerSocketStatus> statusSubscription;
  late final StreamSubscription<Object> errorSubscription;

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
    registerEventListener<SyncErrorEvent>(
      eventName: MultiplayerEvents.syncError,
      parser: (payload) => SyncErrorEvent.fromJson(payload),
      handler: (event) => _handleSyncError(event, onEventError),
      onError: onEventError,
    );

    registerEventListener<ConnectionErrorEvent>(
      eventName: MultiplayerEvents.connectionError,
      parser: (payload) => ConnectionErrorEvent.fromJson(payload),
      handler: (event) => _handleConnectionError(event, onEventError),
      onError: onEventError,
    );

    registerEventListener<HostLeftSessionEvent>(
      eventName: MultiplayerEvents.hostLeftSession,
      parser: (payload) => HostLeftSessionEvent.fromJson(payload),
      handler: (event) => _handleHostLeftSession(event, onEventError),
      onError: onEventError,
    );

    registerEventListener<HostReturnedSessionEvent>(
      eventName: MultiplayerEvents.hostReturnedToSession,
      parser: (payload) => HostReturnedSessionEvent.fromJson(payload),
      handler: (event) => _handleHostReturnedSession(event, onEventError),
      onError: onEventError,
    );

    registerEventListener<HostConnectedSuccessEvent>(
      eventName: MultiplayerEvents.hostConnectedSuccess,
      parser: (payload) => HostConnectedSuccessEvent.fromJson(payload),
      handler: (event) => _handleHostConnectedSuccess(event, onEventError),
      onError: onEventError,
    );

    registerEventListener<GameErrorEvent>(
      eventName: MultiplayerEvents.gameError,
      parser: (payload) => GameErrorEvent.fromJson(payload),
      handler: (event) => _handleGameError(event, onEventError),
      onError: onEventError,
    );

    registerEventListener<UnavailableSessionEvent>(
      eventName: MultiplayerEvents.unavailableSession,
      parser: (payload) => UnavailableSessionEvent.fromJson(payload),
      handler: (event) => _handleUnavailableSession(event, onEventError),
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
    if (!realtime.isConnected) {
      return;
    }
    try {
      realtime.emitClientReady();
      _shouldEmitClientReady = false;
    } catch (error) {
      _lastError = error.toString();
      notifyListeners();
    }
  }

  /// Maneja evento de error de sincronización: cachea error, establece mensaje de error, desconecta socket.
  void _handleSyncError(SyncErrorEvent event, void Function(Object error) onEventError) {
    print('[EVENT] ✗ RECEIVED: sync_error with message=\"${event.message}\" - DISCONNECTING SOCKET');
    _syncErrorDto = event;
    _lastError = event.message ?? MultiplayerConstants.errorSyncDefault;
    realtime.disconnect();
  }

  /// Maneja evento de error de conexión: cachea error y establece mensaje de error.
  void _handleConnectionError(ConnectionErrorEvent event, void Function(Object error) onEventError) {
    print('[EVENT] ✗ RECEIVED: connection_error with message=\"${event.message}\"');
    _connectionErrorDto = event;
    _lastError = event.message ?? MultiplayerConstants.errorConnectionDefault;
  }

  /// Maneja evento de anfitrión salió de la sesión: cachea datos de evento.
  void _handleHostLeftSession(HostLeftSessionEvent event, void Function(Object error) onEventError) {
    _hostLeftDto = event;
  }

  /// Maneja evento de anfitrión retornó a la sesión: cachea datos de evento.
  void _handleHostReturnedSession(HostReturnedSessionEvent event, void Function(Object error) onEventError) {
    _hostReturnedDto = event;
  }

  /// Maneja evento de anfitrión conectado exitosamente: cachea datos de evento y limpia errores.
  void _handleHostConnectedSuccess(HostConnectedSuccessEvent event, void Function(Object error) onEventError) {
    _hostConnectedSuccessDto = event;
    _lastError = null;
  }

  /// Maneja evento de error del juego: cachea error y establece mensaje de error.
  void _handleGameError(GameErrorEvent event, void Function(Object error) onEventError) {
    _gameErrorDto = event;
    _lastError = event.message;
  }

  /// Maneja evento de sesión no disponible: cachea evento, establece mensaje de error, desconecta socket.
  void _handleUnavailableSession(UnavailableSessionEvent event, void Function(Object error) onEventError) {
    print('[EVENT] ✗ RECEIVED: unavailable_session with message="${event.message}" - DISCONNECTING SOCKET');
    _unavailableSessionDto = event;
    _lastError = event.message ?? MultiplayerConstants.errorSessionNotFound;
    realtime.disconnect();
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
    statusSubscription.cancel();
    errorSubscription.cancel();
    cancelAllEventListeners();
    super.dispose();
  }
}