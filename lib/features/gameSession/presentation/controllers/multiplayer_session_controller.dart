import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../application/dtos/multiplayer_socket_events.dart';
import '../../application/use_cases/multiplayer_session_usecases.dart';
import '../../domain/constants/multiplayer_constants.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import '../state/multiplayer_session_state.dart';
import 'session_connection_manager.dart';
import 'session_game_phase_manager.dart';
import 'session_lobby_manager.dart';
import 'session_player_connection_manager.dart';

export '../state/multiplayer_session_state.dart' 
    show SessionPhase, SessionPlayer, LobbyState, GameplayState, SessionLifecycleState;

/// Orquesta la sesión multijugador: oyentes en tiempo real, estado tipado para UI,
/// y comandos host/jugador a través de casos de uso.
/// 
/// Este controlador compone cuatro gestores especializados:
/// - SessionConnectionManager: estado del socket, reconexión, eventos del ciclo de vida
/// - SessionLobbyManager: lista de jugadores, estado del lobby, unirse/salir
/// - SessionGamePhaseManager: flujo de preguntas, resultados, transiciones de fase
/// - SessionPlayerConnectionManager: flujo específico de conexión de jugadores
class MultiplayerSessionController extends ChangeNotifier {
  MultiplayerSessionController({
    required MultiplayerSessionRealtime realtime,
    required InitializeHostLobbyUseCase initializeHostLobbyUseCase,
    required ResolvePinFromQrTokenUseCase resolvePinFromQrTokenUseCase,
    required JoinLobbyUseCase joinLobbyUseCase,
    required LeaveSessionUseCase leaveSessionUseCase,
    required EmitHostStartGameUseCase emitHostStartGameUseCase,
    required EmitHostNextPhaseUseCase emitHostNextPhaseUseCase,
    required EmitHostEndSessionUseCase emitHostEndSessionUseCase,
    required SubmitPlayerAnswerUseCase submitPlayerAnswerUseCase,
  })  : _realtime = realtime,
        _initializeHostLobbyUseCase = initializeHostLobbyUseCase,
        _resolvePinFromQrTokenUseCase = resolvePinFromQrTokenUseCase,
        _joinLobbyUseCase = joinLobbyUseCase,
        _leaveSessionUseCase = leaveSessionUseCase,
        _emitHostStartGameUseCase = emitHostStartGameUseCase,
        _emitHostNextPhaseUseCase = emitHostNextPhaseUseCase,
        _emitHostEndSessionUseCase = emitHostEndSessionUseCase,
        _submitPlayerAnswerUseCase = submitPlayerAnswerUseCase,
        _connectionManager = SessionConnectionManager(realtime: realtime),
        _lobbyManager = SessionLobbyManager(realtime: realtime),
        _gamePhaseManager = SessionGamePhaseManager(realtime: realtime),
        _playerConnectionManager = SessionPlayerConnectionManager(realtime: realtime) {
    // Configura oyentes para todos los gestores
    _setupManagers();
  }

  final MultiplayerSessionRealtime _realtime;
  final InitializeHostLobbyUseCase _initializeHostLobbyUseCase;
  final ResolvePinFromQrTokenUseCase _resolvePinFromQrTokenUseCase;
  final JoinLobbyUseCase _joinLobbyUseCase;
  final LeaveSessionUseCase _leaveSessionUseCase;
  final EmitHostStartGameUseCase _emitHostStartGameUseCase;
  final EmitHostNextPhaseUseCase _emitHostNextPhaseUseCase;
  final EmitHostEndSessionUseCase _emitHostEndSessionUseCase;
  final SubmitPlayerAnswerUseCase _submitPlayerAnswerUseCase;

  final SessionConnectionManager _connectionManager;
  final SessionLobbyManager _lobbyManager;
  final SessionGamePhaseManager _gamePhaseManager;
  final SessionPlayerConnectionManager _playerConnectionManager;

  String? _lastError;

  /// Configura oyentes en todos los sub-gestores para propagar cambios a la UI.
  void _setupManagers() {
    _connectionManager.addListener(_onManagerChanged);
    _lobbyManager.addListener(_onManagerChanged);
    // Also add a specific lobby listener to react to player answer confirmations
    _lobbyManager.addListener(_onLobbyChanged);
    _gamePhaseManager.addListener(_onManagerChanged);
    _playerConnectionManager.addListener(_onManagerChanged);
  }

  void _onManagerChanged() {
    notifyListeners();
  }

  void _onLobbyChanged() {
    // When a PlayerAnswerConfirmationEvent is present, optimistically increment
    // the host submissions counter so the UI reflects incoming answers immediately.
    final confirmation = _lobbyManager.playerAnswerConfirmationDto;
    if (confirmation != null) {
      final current = _gamePhaseManager.hostAnswerSubmissions ?? 0;
      print('[CONTROLLER] ↑ PlayerAnswerConfirmation received — incrementing submissions ${current}→${current + 1}');
      _gamePhaseManager.setHostAnswerSubmissions(current + 1);
      // Clear the confirmation event so we don't double-count it.
      _lobbyManager.clearPlayerAnswerConfirmationDto();
    }
  }

  /// Estado de creación de sala (host)
  bool get isCreatingSession => _lobbyManager.isCreatingSession;
  bool get isJoiningSession => _lobbyManager.isJoiningSession;
  bool get isResolvingQr => _lobbyManager.isResolvingQr;
  String? get lastError => _lastError ?? _connectionManager.lastError;
  String? get sessionPin => _lobbyManager.currentPin ?? _lobbyManager.hostSession?.sessionPin;
  String? get qrToken => _lobbyManager.hostSession?.qrToken;
  String? get currentNickname => _lobbyManager.currentNickname;
  String? get quizTitle => _lobbyManager.hostSession?.quizTitle;
  MultiplayerSocketStatus get socketStatus => _connectionManager.socketStatus;
  MultiplayerRole? get currentRole => _lobbyManager.currentRole;
  List<SessionPlayer> get lobbyPlayers => _lobbyManager.players;
  HostLobbyUpdateEvent? get latestGameStateDto => _lobbyManager.latestGameStateDto;
  QuestionStartedEvent? get currentQuestionDto => _gamePhaseManager.currentQuestionDto;
  HostResultsEvent? get hostResultsDto => _gamePhaseManager.hostResultsDto;
  PlayerResultsEvent? get playerResultsDto => _gamePhaseManager.playerResultsDto;
  HostGameEndEvent? get hostGameEndDto => _gamePhaseManager.hostGameEndDto;
  PlayerGameEndEvent? get playerGameEndDto => _gamePhaseManager.playerGameEndDto;
  SessionClosedEvent? get sessionClosedDto => _gamePhaseManager.sessionClosedDto;
  DateTime? get sessionJoinedAt => _lobbyManager.joinedAt;
  PlayerLeftSessionEvent? get playerLeftDto => _lobbyManager.playerLeftDto;
  HostLeftSessionEvent? get hostLeftDto => _connectionManager.hostLeftDto;
  HostReturnedSessionEvent? get hostReturnedDto => _connectionManager.hostReturnedDto;
  SyncErrorEvent? get syncErrorDto => _connectionManager.syncErrorDto;
  ConnectionErrorEvent? get connectionErrorDto => _connectionManager.connectionErrorDto;
  HostConnectedSuccessEvent? get hostConnectedSuccessDto => _connectionManager.hostConnectedSuccessDto;
  PlayerAnswerConfirmationEvent? get playerAnswerConfirmationDto => _lobbyManager.playerAnswerConfirmationDto;
  GameErrorEvent? get gameErrorDto => _connectionManager.gameErrorDto;
  UnavailableSessionEvent? get unavailableSessionDto => _connectionManager.unavailableSessionDto;
  PlayerConnectedEvent? get playerConnectedDto => _lobbyManager.playerConnectedDto;
  PlayerConnectedToServerEvent? get playerConnectedToServerDto => _lobbyManager.playerConnectedToServerDto;
  DateTime? get questionStartedAt => _gamePhaseManager.questionStartedAt;
  SessionPhase get phase => _gamePhaseManager.phase;
  int get questionSequence => _gamePhaseManager.questionSequence;
  int get hostGameEndSequence => _gamePhaseManager.hostGameEndSequence;
  int get playerGameEndSequence => _gamePhaseManager.playerGameEndSequence;
  int? get hostAnswerSubmissions => _gamePhaseManager.hostAnswerSubmissions;
  bool get isSocketConnected => _realtime.isConnected;

  /// Devuelve una instantánea inmutable del estado actual de la sesión.
  /// Útil para consumidores que prefieren trabajar con objetos de estado inmutable.
  MultiplayerSessionSnapshot get snapshot => MultiplayerSessionSnapshot(
    lobby: LobbyState(
      hostSession: _lobbyManager.hostSession,
      currentPin: _lobbyManager.currentPin,
      currentNickname: _lobbyManager.currentNickname,
      currentRole: _lobbyManager.currentRole,
      players: _lobbyManager.players,
      latestGameStateDto: _lobbyManager.latestGameStateDto,
      isCreatingSession: _lobbyManager.isCreatingSession,
      isJoiningSession: _lobbyManager.isJoiningSession,
      isResolvingQr: _lobbyManager.isResolvingQr,
    ),
    gameplay: GameplayState(
      phase: _gamePhaseManager.phase,
      currentQuestionDto: _gamePhaseManager.currentQuestionDto,
      questionStartedAt: _gamePhaseManager.questionStartedAt,
      questionSequence: _gamePhaseManager.questionSequence,
      hostAnswerSubmissions: _gamePhaseManager.hostAnswerSubmissions,
      hostResultsDto: _gamePhaseManager.hostResultsDto,
      playerResultsDto: _gamePhaseManager.playerResultsDto,
      hostGameEndDto: _gamePhaseManager.hostGameEndDto,
      hostGameEndSequence: _gamePhaseManager.hostGameEndSequence,
      playerGameEndDto: _gamePhaseManager.playerGameEndDto,
      playerGameEndSequence: _gamePhaseManager.playerGameEndSequence,
    ),
    lifecycle: SessionLifecycleState(
      socketStatus: _connectionManager.socketStatus,
      lastError: _lastError ?? _connectionManager.lastError,
      sessionClosedDto: _gamePhaseManager.sessionClosedDto,
      playerLeftDto: _lobbyManager.playerLeftDto,
      hostLeftDto: _connectionManager.hostLeftDto,
      hostReturnedDto: _connectionManager.hostReturnedDto,
      syncErrorDto: _connectionManager.syncErrorDto,
      connectionErrorDto: _connectionManager.connectionErrorDto,
      hostConnectedSuccessDto: _connectionManager.hostConnectedSuccessDto,
      playerAnswerConfirmationDto: _lobbyManager.playerAnswerConfirmationDto,
      gameErrorDto: _connectionManager.gameErrorDto,
      unavailableSessionDto: _connectionManager.unavailableSessionDto,
      shouldEmitClientReady: _connectionManager.shouldEmitClientReady,
    ),
  );

  @override
  void dispose() {
    _connectionManager.removeListener(_onManagerChanged);
    _lobbyManager.removeListener(_onManagerChanged);
    _gamePhaseManager.removeListener(_onManagerChanged);
    _playerConnectionManager.removeListener(_onManagerChanged);
    _connectionManager.dispose();
    _lobbyManager.dispose();
    _gamePhaseManager.dispose();
    _playerConnectionManager.dispose();
    _realtime.disconnect();
    super.dispose();
  }

  /// El host crea la sesión e inicia listeners de sincronización para lobby, fase de juego y eventos del ciclo de vida.
  Future<void> initializeHostLobby({
    required String kahootId,
    String? jwt,
  }) async {
    _resetSessionState(clearHostSession: true);
    _lobbyManager.setIsCreatingSession(true);
    _lastError = null;
    notifyListeners();
    try {
      _lobbyManager.setCurrentRole(MultiplayerRole.host);
      final session = await _initializeHostLobbyUseCase.execute(
        kahootId: kahootId,
        jwt: jwt,
      );
      final sessionPin = session.sessionPin;
      if (sessionPin.isEmpty) {
        throw StateError('El backend no devolvió un PIN de sesión válido.');
      }
      _lobbyManager.setHostSession(session);
      _registerAllListeners();
      _connectionManager.markReadyForSync();
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _lobbyManager.setIsCreatingSession(false);
      notifyListeners();
    }
  }

  /// Resuelve un PIN de sesión a partir de un token QR llamando al servicio backend.
  Future<String> resolvePinFromQrToken(String qrToken) async {
    _lobbyManager.setIsResolvingQr(true);
    _lastError = null;
    notifyListeners();
    try {
      return await _resolvePinFromQrTokenUseCase.execute(qrToken);
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _lobbyManager.setIsResolvingQr(false);
      notifyListeners();
    }
  }

  /// El jugador se conecta a la sala con PIN y nickname, registra oyentes y emite evento de unirse.
  Future<void> joinLobby({
    required String pin,
    required String nickname,
    String? jwt,
  }) async {
    _lobbyManager.setIsJoiningSession(true);
    _lastError = null;
    String safeNickname;
    try {
      safeNickname = _validateNickname(nickname);
    } catch (error) {
      _lastError = error.toString();
      _lobbyManager.setIsJoiningSession(false);
      notifyListeners();
      rethrow;
    }
    _lobbyManager.setCurrentNickname(safeNickname);
    notifyListeners();
    final previousPin = _lobbyManager.currentPin;
    try {
      _lobbyManager.setCurrentRole(MultiplayerRole.player);
      // Prepara el nickname para ser enviado automáticamente cuando se reciba player_connected_to_server
      _playerConnectionManager.setPendingNickname(safeNickname);
      await _joinLobbyUseCase.execute(
        pin: pin,
        jwt: jwt,
      );
      _lobbyManager.setCurrentPin(pin);
      _registerAllListeners();
      _connectionManager.markReadyForSync();
    } catch (error) {
      _lastError = error.toString();
      if (previousPin != null) {
        _lobbyManager.setCurrentPin(previousPin);
      }
      rethrow;
    } finally {
      _lobbyManager.setIsJoiningSession(false);
      notifyListeners();
    }
  }

  /// El jugador cambia su nickname emitiendo nuevo evento de unirse con nickname actualizado.
  Future<void> joinLobbyWithNickname({required String nickname}) async {
    String safeNickname;
    try {
      safeNickname = _validateNickname(nickname);
    } catch (error) {
      rethrow;
    }
    _lobbyManager.setCurrentNickname(safeNickname);
    notifyListeners();
    try {
      // Verifica que el socket esté conectado antes de emitir player_join
      if (!_realtime.isConnected) {
        throw StateError(
          'Socket is not connected. Unable to emit player_join. Please reconnect.',
        );
      }
      _realtime.emitPlayerJoin(PlayerJoinPayload(nickname: safeNickname));
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    }
  }

  /// El host inicia la partida emitiendo evento de inicio para disparar transición a fase de pregunta.
  void emitHostStartGame() {
    _emitHostStartGameUseCase.execute();
  }

  /// El host avanza a la siguiente fase (resultados o siguiente pregunta) emitiendo evento de avance de fase.
  void emitHostNextPhase() {
    _emitHostNextPhaseUseCase.execute();
  }

  /// El host fuerza fin de sesión emitiendo evento de fin de sesión a todos los jugadores.
  /// Intenta emitir el evento, y si el socket está desconectado intentará reconectar
  /// brevemente usando el PIN de la sesión antes de volver a intentar la emisión.
  /// Emit host_end_session. By default, if the socket is disconnected we will
  /// attempt a brief reconnection to ensure the event is delivered. For the
  /// "Salir y cerrar sesión" action we can set `tryReconnect=false` to avoid
  /// any reconnection attempts and simply leave the session locally.
  Future<void> emitHostEndSession({bool tryReconnect = true}) async {
    _lastError = null;
    try {
      _emitHostEndSessionUseCase.execute();
    } catch (error) {
      if (!tryReconnect) {
        // Don't attempt reconnection — just record the error and continue to leave.
        _lastError = error.toString();
      } else {
        // If the socket is not connected, attempt a brief reconnect then retry
        if (!_realtime.isConnected) {
          try {
            final pin = _lobbyManager.currentPin ?? _lobbyManager.hostSession?.sessionPin;
            if (pin == null || pin.isEmpty) throw StateError('No session PIN available to reconnect the socket.');
            print('[SESSION] ✱ Socket disconnected — attempting reconnection to emit host_end_session (pin=$pin)');
            await _realtime.connect(MultiplayerSocketParams(pin: pin, role: MultiplayerRole.host));
            // Reintentar emisión
            _emitHostEndSessionUseCase.execute();
          } catch (reconnectError) {
            _lastError = reconnectError.toString();
            print('[SESSION] ✗ Failed to reconnect/emit host_end_session: $reconnectError');
            rethrow;
          }
        } else {
          _lastError = error.toString();
          rethrow;
        }
      }
    } finally {
      // Leave session and cleanup regardless of whether we retried or not.
      try {
        await leaveSession();
      } catch (_) {
        // Ignore errors when leaving to avoid blocking the UI
      }
    }
  }

  /// El jugador envía respuesta con ID de pregunta, opciones de respuesta y tiempo consumido; emitido al servidor.
  Future<void> submitPlayerAnswer({
    required String questionId,
    required List<String> answerIds,
    required int timeElapsedMs,
  }) async {
    print('[EVENT] → EMIT: player_submit_answer (questionId=$questionId, answers=${answerIds.join(',')}, timeElapsedMs=$timeElapsedMs)');
    _submitPlayerAnswerUseCase.execute(
      questionId: questionId,
      answerIds: answerIds,
      timeElapsedMs: timeElapsedMs,
    );
  }

  /// Limpia estado y abandona la sesión emitiendo evento de salida al servidor.
  Future<void> leaveSession() async {
    await _leaveSessionUseCase.execute();
    _resetSessionState(clearHostSession: true);
    notifyListeners();
  }

  /// Devuelve verdadero si el host puede iniciar el juego (socket conectado y jugadores en lobby).
  bool get canHostStartGame =>
      _connectionManager.socketStatus == MultiplayerSocketStatus.connected &&
      _lobbyManager.players.isNotEmpty;
      
  /// Limpia resultados parciales del host y notifica a oyentes.
  void clearHostResults() {
    _gamePhaseManager.clearHostResults();
  }

  /// Limpia caché de cierre de juego (host) y notifica a oyentes.
  void clearHostGameEnd() {
    _gamePhaseManager.clearHostGameEnd();
  }

  /// Limpia caché de cierre de juego (jugador) y notifica a oyentes.
  void clearPlayerGameEnd() {
    _gamePhaseManager.clearPlayerGameEnd();
  }

  /// Limpia cache de resultados de pregunta (jugador) y notifica a oyentes.
  void clearPlayerResults() {
    _gamePhaseManager.clearPlayerResults();
  }

  /// Limpia evento de sesión cerrada y notifica a oyentes.
  void clearSessionClosed() {
    _gamePhaseManager.clearSessionClosed();
  }

  // ==================== Private Methods ====================

  /// Registra todos los oyentes (lobby, fase de juego, ciclo de vida y conexión del jugador) con manejador de errores.
  void _registerAllListeners() {
    _lobbyManager.registerLobbyListeners(_handleEventError);
    _gamePhaseManager.registerGamePhaseListeners(_handleEventError);
    _connectionManager.registerLifecycleListeners(_handleEventError);
    _playerConnectionManager.registerPlayerConnectionListeners(_handleEventError);
  }

  /// Limpia cachés y contadores entre sesiones o al salir.
  void _resetSessionState({bool clearHostSession = false}) {
    _lobbyManager.resetLobbyState(clearHostSession: clearHostSession);
    _gamePhaseManager.resetGamePhaseState();
    _lastError = null;
  }

  /// Valida nickname y devuelve versión sanitizada; falla si no cumple formato.
  String _validateNickname(String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.length < MultiplayerConstants.nicknameMinLength || 
        trimmed.length > MultiplayerConstants.nicknameMaxLength) {
      throw StateError(MultiplayerConstants.errorInvalidNickname(
        MultiplayerConstants.nicknameMinLength,
        MultiplayerConstants.nicknameMaxLength,
      ));
    }
    return trimmed;
  }

  /// Captura error de parsing/oyente y notifica a oyentes de UI.
  void _handleEventError(Object error) {
    _lastError = error.toString();
    notifyListeners();
  }
}