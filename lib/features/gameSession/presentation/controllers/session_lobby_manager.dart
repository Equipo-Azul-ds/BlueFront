import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import '../state/multiplayer_session_state.dart';

/// Gestiona el estado del lobby: jugadores, información de juego y ciclo de vida del lobby.
/// Responsabilidades: actualizaciones de lista de jugadores, estado de lobby de anfitrión/jugador,
/// manejo de unirse/salir de jugadores.
class SessionLobbyManager extends ChangeNotifier {
  SessionLobbyManager({
    required MultiplayerSessionRealtime realtime,
  }) : _realtime = realtime;

  final MultiplayerSessionRealtime _realtime;

  CreateSessionResponse? _hostSession;
  String? _currentPin;
  String? _currentNickname;
  MultiplayerRole? _currentRole;
  List<SessionPlayer> _players = const [];
  HostLobbyUpdateEvent? _latestGameStateDto;
  bool _isCreatingSession = false;
  bool _isJoiningSession = false;
  bool _isResolvingQr = false;

  PlayerLeftSessionEvent? _playerLeftDto;
  PlayerAnswerConfirmationEvent? _playerAnswerConfirmationDto;
  PlayerConnectedEvent? _playerConnectedDto;
  PlayerConnectedToServerEvent? _playerConnectedToServerDto;

  StreamSubscription<dynamic>? _gameStateSubscription;
  StreamSubscription<dynamic>? _hostLobbySubscription;
  StreamSubscription<dynamic>? _playerConnectedSubscription;
  StreamSubscription<dynamic>? _playerConnectedToServerSubscription;
  StreamSubscription<dynamic>? _playerLeftSubscription;
  StreamSubscription<dynamic>? _playerAnswerConfirmationSubscription;

  // Getters
  CreateSessionResponse? get hostSession => _hostSession;
  String? get currentPin => _currentPin;
  String? get currentNickname => _currentNickname;
  MultiplayerRole? get currentRole => _currentRole;
  List<SessionPlayer> get players => List.unmodifiable(_players);
  HostLobbyUpdateEvent? get latestGameStateDto => _latestGameStateDto;
  bool get isCreatingSession => _isCreatingSession;
  bool get isJoiningSession => _isJoiningSession;
  bool get isResolvingQr => _isResolvingQr;
  PlayerLeftSessionEvent? get playerLeftDto => _playerLeftDto;
  PlayerAnswerConfirmationEvent? get playerAnswerConfirmationDto => _playerAnswerConfirmationDto;
  PlayerConnectedEvent? get playerConnectedDto => _playerConnectedDto;
  PlayerConnectedToServerEvent? get playerConnectedToServerDto => _playerConnectedToServerDto;

  /// Establece la sesión del anfitrión y el PIN actual.
  void setHostSession(CreateSessionResponse session) {
    _hostSession = session;
    _currentPin = session.sessionPin;
    notifyListeners();
  }

  /// Establece el PIN actual (útil al unirse).
  void setCurrentPin(String pin) {
    _currentPin = pin;
    notifyListeners();
  }


  /// Establece el apodo actual del jugador.
  void setCurrentNickname(String nickname) {
    _currentNickname = nickname;
    notifyListeners();
  }

  /// Establece el rol actual (anfitrión o jugador).
  void setCurrentRole(MultiplayerRole role) {
    _currentRole = role;
    notifyListeners();
  }

  /// Establece el estado de carga para la creación de sesión.
  void setIsCreatingSession(bool value) {
    _isCreatingSession = value;
    notifyListeners();
  }

  /// Establece el estado de carga para unirse a la sesión.
  void setIsJoiningSession(bool value) {
    _isJoiningSession = value;
    notifyListeners();
  }

  /// Establece el estado de carga para la resolución del código QR.
  void setIsResolvingQr(bool value) {
    _isResolvingQr = value;
    notifyListeners();
  }

  /// Registra los listeners para eventos del lobby.
  void registerLobbyListeners(
    void Function(Object error) onEventError,
  ) {
    _gameStateSubscription?.cancel();
    _gameStateSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.gameStateUpdate)
        .listen(
          (payload) => _handleGameStateSync(payload, onEventError),
          onError: onEventError,
        );

    _hostLobbySubscription?.cancel();
    _hostLobbySubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.hostLobbyUpdate)
        .listen(
          (payload) => _handleHostLobbyUpdate(payload, onEventError),
          onError: onEventError,
        );

    _playerConnectedSubscription?.cancel();
    _playerConnectedSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.playerConnectedToSession)
        .listen(
          (payload) => _handlePlayerConnectedToSession(payload, onEventError),
          onError: onEventError,
        );

    _playerConnectedToServerSubscription?.cancel();
    _playerConnectedToServerSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.playerConnectedToServer)
        .listen(
          (payload) => _handlePlayerConnectedToServer(payload, onEventError),
          onError: onEventError,
        );

    _playerLeftSubscription?.cancel();
    _playerLeftSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.playerLeftSession)
        .listen(
          (payload) => _handlePlayerLeftSession(payload, onEventError),
          onError: onEventError,
        );

    _playerAnswerConfirmationSubscription?.cancel();
    _playerAnswerConfirmationSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.playerAnswerConfirmation)
        .listen(
          (payload) => _handlePlayerAnswerConfirmation(payload, onEventError),
          onError: onEventError,
        );
  }

  void _handleGameStateSync(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    // Procesa actualización de estado del juego desde el servidor
    try {
      final event = HostLobbyUpdateEvent.fromJson(payload);
      _latestGameStateDto = event;
      _applyPlayersFromPayload(event.players);
      notifyListeners();
    } catch (error) {
      onEventError(error);
    }
  }

  void _handleHostLobbyUpdate(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    // Procesa actualizaciones de lobby del anfitrión (nuevos jugadores, cambios de estado)
    try {
      final event = HostLobbyUpdateEvent.fromJson(payload);
      print('[EVENT] ← RECEIVED: host_lobby_update (players=${event.players.length})');
      _latestGameStateDto = event;
      _applyPlayersFromPayload(event.players);
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing host_lobby_update: $error');
      onEventError(error);
    }
  }

  void _handlePlayerConnectedToSession(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    // Procesa confirmación de conexión del jugador, actualiza nickname local si es necesario
    try {
      final event = PlayerConnectedEvent.fromJson(payload);
      print('[EVENT] ← RECEIVED: player_connected_to_session (nickname=${event.nickname})');
      _playerConnectedDto = event;
      if (event.nickname.isNotEmpty) {
        _currentNickname = event.nickname;
      }
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing player_connected_to_session: $error');
      onEventError(error);
    }
  }

  void _handlePlayerConnectedToServer(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    // Procesa confirmación de conexión inicial del jugador al servidor (primer client_ready)
    // Provee el tema de fondo de la partida
    try {
      final event = PlayerConnectedToServerEvent.fromJson(payload);
      print('[EVENT] ← RECEIVED: player_connected_to_server (status=${event.status}, theme=${event.theme?.name})');
      _playerConnectedToServerDto = event;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing player_connected_to_server: $error');
      onEventError(error);
    }
  }

  void _handlePlayerLeftSession(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    // Marca jugador como desconectado cuando abandona la sesión
    try {
      final event = PlayerLeftSessionEvent.fromJson(payload);
      print('[EVENT] ← RECEIVED: player_left_session (nickname=${event.nickname}, userId=${event.userId})');
      _playerLeftDto = event;
      final leavingId = event.userId;
      final leavingNick = event.nickname;
      if (_players.isNotEmpty && (leavingId != null || leavingNick != null)) {
        _players = List.unmodifiable(
          _players.map((p) {
            final idMatches = leavingId != null && p.playerId == leavingId;
            final nickMatches = leavingNick != null && p.nickname == leavingNick;
            return (idMatches || nickMatches) ? p.markDisconnected() : p;
          }),
        );
      }
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing player_left_session: $error');
      onEventError(error);
    }
  }

  void _handlePlayerAnswerConfirmation(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    // Procesa confirmación de que la respuesta del jugador fue recibida
    try {
      final event = PlayerAnswerConfirmationEvent.fromJson(payload);
      _playerAnswerConfirmationDto = event;
      notifyListeners();
    } catch (error) {
      onEventError(error);
    }
  }

  void _applyPlayersFromPayload(List<SessionPlayerSummary> players) {
    // Convierte resumen de jugadores en objetos SessionPlayer y los almacena
    _players = List.unmodifiable(
      players
          .map((p) => SessionPlayer(playerId: p.playerId, nickname: p.nickname))
          .toList(),
    );
  }

  /// Reinicia el estado del lobby (normalmente al salir o unirse a una nueva sesión).
  void resetLobbyState({bool clearHostSession = false}) {
    if (clearHostSession) {
      _hostSession = null;
      _currentPin = null;
      _currentNickname = null;
      _currentRole = null;
    }
    _players = const [];
    _latestGameStateDto = null;
    _isCreatingSession = false;
    _isJoiningSession = false;
    _isResolvingQr = false;
    _playerLeftDto = null;
    _playerAnswerConfirmationDto = null;
    _playerConnectedDto = null;
    _playerConnectedToServerDto = null;
    notifyListeners();
  }

  /// Limpia el evento de jugador que se fue después de procesarlo.
  void clearPlayerLeftDto() {
    _playerLeftDto = null;
    notifyListeners();
  }

  /// Limpia el evento de confirmación de respuesta del jugador después de procesarlo.
  void clearPlayerAnswerConfirmationDto() {
    _playerAnswerConfirmationDto = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _gameStateSubscription?.cancel();
    _hostLobbySubscription?.cancel();
    _playerConnectedSubscription?.cancel();
    _playerConnectedToServerSubscription?.cancel();
    _playerLeftSubscription?.cancel();
    _playerAnswerConfirmationSubscription?.cancel();
    super.dispose();
  }
}
