import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import '../state/multiplayer_session_state.dart';
import 'base_session_manager.dart';

/// Gestiona el estado del lobby: jugadores, información de juego y ciclo de vida del lobby.
/// Responsabilidades: actualizaciones de lista de jugadores, estado de lobby de anfitrión/jugador,
/// manejo de unirse/salir de jugadores.
class SessionLobbyManager extends BaseSessionManager {
  SessionLobbyManager({
    required MultiplayerSessionRealtime realtime,
  }) : super(realtime: realtime);

  // State fields
  CreateSessionResponse? _hostSession;
  String? _currentPin;
  DateTime? _joinedAt;
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
    _joinedAt = DateTime.now();
    notifyListeners();
  }

  /// Establece el PIN actual (útil al unirse).
  void setCurrentPin(String pin) {
    _currentPin = pin;
    _joinedAt = DateTime.now();
    notifyListeners();
  }

  /// Tiempo en que el cliente se unió a la sesión actual (si aplica).
  DateTime? get joinedAt => _joinedAt;


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
    registerEventListener<HostLobbyUpdateEvent>(
      eventName: MultiplayerEvents.gameStateUpdate,
      parser: (payload) => HostLobbyUpdateEvent.fromJson(payload),
      handler: (event) => _handleGameStateSync(event),
      onError: onEventError,
    );

    registerEventListener<HostLobbyUpdateEvent>(
      eventName: MultiplayerEvents.hostLobbyUpdate,
      parser: (payload) => HostLobbyUpdateEvent.fromJson(payload),
      handler: (event) => _handleHostLobbyUpdate(event),
      onError: onEventError,
    );

    registerEventListener<PlayerConnectedEvent>(
      eventName: MultiplayerEvents.playerConnectedToSession,
      parser: (payload) => PlayerConnectedEvent.fromJson(payload),
      handler: (event) => _handlePlayerConnectedToSession(event),
      onError: onEventError,
    );

    registerEventListener<PlayerConnectedToServerEvent>(
      eventName: MultiplayerEvents.playerConnectedToServer,
      parser: (payload) => PlayerConnectedToServerEvent.fromJson(payload),
      handler: (event) => _handlePlayerConnectedToServer(event),
      onError: onEventError,
    );

    registerEventListener<PlayerLeftSessionEvent>(
      eventName: MultiplayerEvents.playerLeftSession,
      parser: (payload) => PlayerLeftSessionEvent.fromJson(payload),
      handler: (event) => _handlePlayerLeftSession(event),
      onError: onEventError,
    );

    registerEventListener<PlayerAnswerConfirmationEvent>(
      eventName: MultiplayerEvents.playerAnswerConfirmation,
      parser: (payload) => PlayerAnswerConfirmationEvent.fromJson(payload),
      handler: (event) => _handlePlayerAnswerConfirmation(event),
      onError: onEventError,
    );
  }

  void _handleGameStateSync(HostLobbyUpdateEvent event) {
    _latestGameStateDto = event;
    _applyPlayersFromPayload(event.players);
  }

  void _handleHostLobbyUpdate(HostLobbyUpdateEvent event) {
    print('[EVENT] ← RECEIVED: host_lobby_update (players=${event.players.length})');
    _latestGameStateDto = event;
    _applyPlayersFromPayload(event.players);
  }

  void _handlePlayerConnectedToSession(PlayerConnectedEvent event) {
    print('[EVENT] ← RECEIVED: player_connected_to_session (nickname=${event.nickname})');
    _playerConnectedDto = event;
    if (event.nickname.isNotEmpty) {
      // Use setter so listeners are notified and UI updates accordingly
      setCurrentNickname(event.nickname);
    }
  }

  void _handlePlayerConnectedToServer(PlayerConnectedToServerEvent event) {
    print('[EVENT] ← RECEIVED: player_connected_to_server (status=${event.status}, theme=${event.theme?.name})');
    _playerConnectedToServerDto = event;
  }

  void _handlePlayerLeftSession(PlayerLeftSessionEvent event) {
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
  }

  void _handlePlayerAnswerConfirmation(PlayerAnswerConfirmationEvent event) {
    _playerAnswerConfirmationDto = event;
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
    cancelAllEventListeners();
    super.dispose();
  }
}