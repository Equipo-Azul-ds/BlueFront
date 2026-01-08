import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../application/dtos/multiplayer_socket_events.dart';
import '../../application/use_cases/multiplayer_session_usecases.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';

/// Fases de la sesión para renderizado/navegación en UI.
enum SessionPhase { lobby, question, results, end }

/// Jugador en lobby o leaderboard básico (sin métricas de juego).
class SessionPlayer {
  const SessionPlayer({required this.playerId, required this.nickname, this.isDisconnected = false});

  final String playerId;
  final String nickname;
  final bool isDisconnected;

  factory SessionPlayer.fromJson(Map<String, dynamic> json) {
    final idValue = json['playerId']?.toString() ?? '';
    final nicknameValue = json['nickname']?.toString() ?? 'Jugador';
    return SessionPlayer(playerId: idValue, nickname: nicknameValue);
  }

  SessionPlayer markDisconnected() => SessionPlayer(
        playerId: playerId,
        nickname: nickname,
        isDisconnected: true,
      );
}

/// Orquesta la sesión multijugador: listeners de socket, estado tipado para UI
/// y comandos del host/jugador mediante casos de uso.
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
        _submitPlayerAnswerUseCase = submitPlayerAnswerUseCase {
    // Reaccionar a cambios de conexión para reemitir client_ready y propagar UI.
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
    // Errores de socket hacia la UI.
    _errorSubscription = _realtime.errors.listen((error) {
      _lastError = error.toString();
      notifyListeners();
    });
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

  CreateSessionResponse? _hostSession;
  bool _isCreatingSession = false;
  bool _isJoiningSession = false;
  bool _isResolvingQr = false;
  String? _lastError;
  String? _currentPin;
  String? _currentNickname;
  MultiplayerSocketStatus _socketStatus = MultiplayerSocketStatus.idle;
  MultiplayerRole? _currentRole;
  List<SessionPlayer> _players = const [];
  Map<String, dynamic>? _latestGameState;
  Map<String, dynamic>? _currentQuestionEvent;
  QuestionStartedEvent? _currentQuestionDto;
  Map<String, dynamic>? _hostResultsEvent;
  HostResultsEvent? _hostResultsDto;
  Map<String, dynamic>? _hostGameEndEvent;
  HostGameEndEvent? _hostGameEndDto;
  Map<String, dynamic>? _playerGameEndEvent;
  PlayerGameEndEvent? _playerGameEndDto;
  Map<String, dynamic>? _sessionClosedEvent;
  Map<String, dynamic>? _playerResultsEvent;
  PlayerResultsEvent? _playerResultsDto;
  Map<String, dynamic>? _playerLeftEvent;
  Map<String, dynamic>? _hostLeftEvent;
  Map<String, dynamic>? _hostReturnedEvent;
  Map<String, dynamic>? _syncErrorEvent;
  Map<String, dynamic>? _connectionErrorEvent;
  DateTime? _questionStartedAt;
  SessionPhase _phase = SessionPhase.lobby;
  int _questionSequence = 0;
  int _hostGameEndSequence = 0;
  int _playerGameEndSequence = 0;
  int? _hostAnswerSubmissions;
  bool _shouldEmitClientReady = false;

  StreamSubscription<MultiplayerSocketStatus>? _statusSubscription;
  StreamSubscription<Object>? _errorSubscription;
  StreamSubscription<dynamic>? _gameStateSubscription;
  StreamSubscription<dynamic>? _questionStartedSubscription;
  StreamSubscription<dynamic>? _hostResultsSubscription;
  StreamSubscription<dynamic>? _hostGameEndSubscription;
  StreamSubscription<dynamic>? _playerGameEndSubscription;
  StreamSubscription<dynamic>? _sessionClosedSubscription;
  StreamSubscription<dynamic>? _playerResultsSubscription;
  StreamSubscription<dynamic>? _hostLobbySubscription;
  StreamSubscription<dynamic>? _playerConnectedSubscription;
  StreamSubscription<dynamic>? _hostAnswerUpdateSubscription;
  StreamSubscription<dynamic>? _playerLeftSubscription;
  StreamSubscription<dynamic>? _hostLeftSubscription;
  StreamSubscription<dynamic>? _hostReturnedSubscription;
  StreamSubscription<dynamic>? _syncErrorSubscription;
  StreamSubscription<dynamic>? _connectionErrorSubscription;

  /// Estado de creación de sala (host).
  bool get isCreatingSession => _isCreatingSession;
  bool get isJoiningSession => _isJoiningSession;
  bool get isResolvingQr => _isResolvingQr;
  String? get lastError => _lastError;
  String? get sessionPin => _currentPin ?? _hostSession?.sessionPin;
  String? get qrToken => _hostSession?.qrToken;
  String? get currentNickname => _currentNickname;
  String? get quizTitle =>
      _latestGameState?['quizTitle']?.toString() ?? _hostSession?.quizTitle;
  MultiplayerSocketStatus get socketStatus => _socketStatus;
  MultiplayerRole? get currentRole => _currentRole;
  List<SessionPlayer> get lobbyPlayers => List.unmodifiable(_players);
  Map<String, dynamic>? get latestGameState =>
      _latestGameState == null ? null : Map<String, dynamic>.from(_latestGameState!);
    Map<String, dynamic>? get currentQuestion => _currentQuestionEvent == null
      ? null
      : Map<String, dynamic>.from(_currentQuestionEvent!);
    QuestionStartedEvent? get currentQuestionDto => _currentQuestionDto;
    Map<String, dynamic>? get hostResults => _hostResultsEvent == null
      ? null
      : Map<String, dynamic>.from(_hostResultsEvent!);
    HostResultsEvent? get hostResultsDto => _hostResultsDto;
    Map<String, dynamic>? get playerResults => _playerResultsEvent == null
      ? null
      : Map<String, dynamic>.from(_playerResultsEvent!);
    PlayerResultsEvent? get playerResultsDto => _playerResultsDto;
    Map<String, dynamic>? get hostGameEnd => _hostGameEndEvent == null
      ? null
      : Map<String, dynamic>.from(_hostGameEndEvent!);
    HostGameEndEvent? get hostGameEndDto => _hostGameEndDto;
    Map<String, dynamic>? get playerGameEnd => _playerGameEndEvent == null
      ? null
      : Map<String, dynamic>.from(_playerGameEndEvent!);
    PlayerGameEndEvent? get playerGameEndDto => _playerGameEndDto;
    Map<String, dynamic>? get sessionClosedPayload => _sessionClosedEvent == null
      ? null
      : Map<String, dynamic>.from(_sessionClosedEvent!);
    Map<String, dynamic>? get playerLeftPayload => _playerLeftEvent == null
      ? null
      : Map<String, dynamic>.from(_playerLeftEvent!);
    Map<String, dynamic>? get hostLeftPayload => _hostLeftEvent == null
      ? null
      : Map<String, dynamic>.from(_hostLeftEvent!);
    Map<String, dynamic>? get hostReturnedPayload => _hostReturnedEvent == null
      ? null
      : Map<String, dynamic>.from(_hostReturnedEvent!);
    Map<String, dynamic>? get syncErrorPayload => _syncErrorEvent == null
      ? null
      : Map<String, dynamic>.from(_syncErrorEvent!);
    Map<String, dynamic>? get connectionErrorPayload => _connectionErrorEvent == null
      ? null
      : Map<String, dynamic>.from(_connectionErrorEvent!);
    DateTime? get questionStartedAt => _questionStartedAt;
    SessionPhase get phase => _phase;
    int get questionSequence => _questionSequence;
    int get hostGameEndSequence => _hostGameEndSequence;
    int get playerGameEndSequence => _playerGameEndSequence;
    int? get hostAnswerSubmissions => _hostAnswerSubmissions;

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    _gameStateSubscription?.cancel();
    _questionStartedSubscription?.cancel();
    _hostResultsSubscription?.cancel();
    _hostGameEndSubscription?.cancel();
    _playerGameEndSubscription?.cancel();
    _sessionClosedSubscription?.cancel();
    _playerResultsSubscription?.cancel();
    _hostLobbySubscription?.cancel();
    _playerConnectedSubscription?.cancel();
    _hostAnswerUpdateSubscription?.cancel();
    _playerLeftSubscription?.cancel();
    _hostLeftSubscription?.cancel();
    _hostReturnedSubscription?.cancel();
    _syncErrorSubscription?.cancel();
    _connectionErrorSubscription?.cancel();
    _realtime.disconnect();
    super.dispose();
  }

  /// El host crea la sesión e inicia listeners de sincronización.
  Future<void> initializeHostLobby({
    required String kahootId,
    String? jwt,
  }) async {
    _resetSessionState();
    _isCreatingSession = true;
    _lastError = null;
    notifyListeners();
    try {
      _currentRole = MultiplayerRole.host;
      _hostSession = await _initializeHostLobbyUseCase.execute(
        kahootId: kahootId,
        jwt: jwt,
      );
      final sessionPin = _hostSession?.sessionPin;
      if (sessionPin == null || sessionPin.isEmpty) {
        throw StateError('El backend no devolvió un PIN de sesión válido.');
      }
      _currentPin = sessionPin;
      _registerSyncListeners();
      _registerRealtimeListeners();
      _markReadyForSync();
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _isCreatingSession = false;
      notifyListeners();
    }
  }

  /// Resuelve un PIN a partir de un token QR.
  Future<String> resolvePinFromQrToken(String qrToken) async {
    _isResolvingQr = true;
    _lastError = null;
    notifyListeners();
    try {
      return await _resolvePinFromQrTokenUseCase.execute(qrToken);
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _isResolvingQr = false;
      notifyListeners();
    }
  }

  /// El jugador se conecta a la sala y envía su nickname.
  Future<void> joinLobby({
    required String pin,
    required String nickname,
    String? jwt,
  }) async {
    _isJoiningSession = true;
    _lastError = null;
    String safeNickname;
    try {
      safeNickname = _validateNickname(nickname);
    } catch (error) {
      _lastError = error.toString();
      _isJoiningSession = false;
      notifyListeners();
      rethrow;
    }
    _currentNickname = safeNickname;
    notifyListeners();
    final previousPin = _currentPin;
    try {
      _players = const [];
      _currentRole = MultiplayerRole.player;
      await _joinLobbyUseCase.execute(
        pin: pin,
        jwt: jwt,
      );
      _currentPin = pin;
      _registerSyncListeners();
      _registerRealtimeListeners();
      _markReadyForSync();
      _realtime.emitPlayerJoin(PlayerJoinPayload(nickname: safeNickname));
    } catch (error) {
      _lastError = error.toString();
      _currentPin = previousPin;
      rethrow;
    } finally {
      _isJoiningSession = false;
      notifyListeners();
    }
  }

  /// Host inicia la partida.
  void emitHostStartGame() {
    _emitHostStartGameUseCase.execute();
  }

  /// Host avanza a la siguiente fase (resultados o siguiente pregunta).
  void emitHostNextPhase() {
    _emitHostNextPhaseUseCase.execute();
  }

  /// Host fuerza fin de sesión.
  void emitHostEndSession() {
    _emitHostEndSessionUseCase.execute();
  }

  /// Jugador envía respuesta con tiempo consumido.
  Future<void> submitPlayerAnswer({
    required String questionId,
    required List<String> answerIds,
    required int timeElapsedMs,
  }) async {
    _submitPlayerAnswerUseCase.execute(
      questionId: questionId,
      answerIds: answerIds,
      timeElapsedMs: timeElapsedMs,
    );
  }

  /// Limpia estado y abandona la sesión.
  Future<void> leaveSession() async {
    await _leaveSessionUseCase.execute();
    _resetSessionState(clearHostSession: true);
    notifyListeners();
  }

  /// True si el host puede iniciar juego (socket ok y hay jugadores en lobby).
  bool get canHostStartGame =>
      _socketStatus == MultiplayerSocketStatus.connected &&
      _players.isNotEmpty;
      
  /// Limpia resultados parciales del host.
  void clearHostResults() {
    _hostResultsEvent = null;
    notifyListeners();
  }

  /// Limpia caché de cierre de juego (host).
  void clearHostGameEnd() {
    _hostGameEndEvent = null;
    notifyListeners();
  }

  /// Limpia caché de cierre de juego (jugador).
  void clearPlayerGameEnd() {
    _playerGameEndEvent = null;
    notifyListeners();
  }

  /// Limpia cache de resultados de pregunta (jugador).
  void clearPlayerResults() {
    _playerResultsEvent = null;
    notifyListeners();
  }

  /// Limpia evento de sesión cerrada.
  void clearSessionClosed() {
    _sessionClosedEvent = null;
    notifyListeners();
  }

  /// Limpia cachés y contadores entre sesiones o al salir.
  void _resetSessionState({bool clearHostSession = false}) {
    if (clearHostSession) {
      _hostSession = null;
      _currentPin = null;
      _currentNickname = null;
      _currentRole = null;
    }
    _players = const [];
    _latestGameState = null;
    _lastError = null;
    _currentQuestionEvent = null;
    _currentQuestionDto = null;
    _hostResultsEvent = null;
    _hostResultsDto = null;
    _playerResultsEvent = null;
    _playerResultsDto = null;
    _hostGameEndEvent = null;
    _hostGameEndDto = null;
    _playerGameEndEvent = null;
    _playerGameEndDto = null;
    _sessionClosedEvent = null;
    _playerLeftEvent = null;
    _hostLeftEvent = null;
    _hostReturnedEvent = null;
    _syncErrorEvent = null;
    _connectionErrorEvent = null;
    _questionStartedAt = null;
    _phase = SessionPhase.lobby;
    _questionSequence = 0;
    _hostGameEndSequence = 0;
    _playerGameEndSequence = 0;
    _hostAnswerSubmissions = null;
    _shouldEmitClientReady = false;
  }

  /// Registra listeners de sincronización inicial (estado general + lobby).
  void _registerSyncListeners() {
    _registerGameStateListener();
    _registerLobbyListeners();
  }

  /// Sync inicial/recuperación de lobby.
  void _registerGameStateListener() {
    _gameStateSubscription?.cancel();
    _gameStateSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('game_state_update')
        .listen(_handleGameStateSync, onError: _handleEventError);
  }

  /// Eventos que pueden llegar en lobby o reconexiones.
  void _registerLobbyListeners() {
    _hostLobbySubscription?.cancel();
    _hostLobbySubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('host_lobby_update')
        .listen(_handleHostLobbyUpdate, onError: _handleEventError);

    _playerConnectedSubscription?.cancel();
    _playerConnectedSubscription = _realtime
      .listenToServerEvent<Map<String, dynamic>>('player_connected_to_session')
        .listen(_handlePlayerConnectedToSession, onError: _handleEventError);

    _hostAnswerUpdateSubscription?.cancel();
    _hostAnswerUpdateSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('host_answer_update')
        .listen(_handleHostAnswerUpdate, onError: _handleEventError);

    _playerLeftSubscription?.cancel();
    _playerLeftSubscription = _realtime
      .listenToServerEvent<Map<String, dynamic>>('player_left_session')
      .listen(_handlePlayerLeftSession, onError: _handleEventError);

    _hostLeftSubscription?.cancel();
    _hostLeftSubscription = _realtime
      .listenToServerEvent<Map<String, dynamic>>('host_left_session')
      .listen(_handleHostLeftSession, onError: _handleEventError);

    _hostReturnedSubscription?.cancel();
    _hostReturnedSubscription = _realtime
      .listenToServerEvent<Map<String, dynamic>>('host_returned_to_session')
      .listen(_handleHostReturnedSession, onError: _handleEventError);

    _syncErrorSubscription?.cancel();
    _syncErrorSubscription = _realtime
      .listenToServerEvent<Map<String, dynamic>>('sync_error')
      .listen(_handleSyncError, onError: _handleEventError);

    _connectionErrorSubscription?.cancel();
    _connectionErrorSubscription = _realtime
      .listenToServerEvent<Map<String, dynamic>>('connection_error')
      .listen(_handleConnectionError, onError: _handleEventError);
  }

  /// Eventos de juego en vivo (preguntas, resultados, fin de juego).
  void _registerRealtimeListeners() {
    _questionStartedSubscription?.cancel();
    _questionStartedSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('question_started')
        .listen(_handleQuestionStarted, onError: _handleEventError);

    _hostResultsSubscription?.cancel();
    _hostResultsSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('host_results')
        .listen(_handleHostResults, onError: _handleEventError);

    _hostGameEndSubscription?.cancel();
    _hostGameEndSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('host_game_end')
        .listen(_handleHostGameEnd, onError: _handleEventError);

    _playerGameEndSubscription?.cancel();
    _playerGameEndSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('player_game_end')
        .listen(_handlePlayerGameEnd, onError: _handleEventError);

    _sessionClosedSubscription?.cancel();
    _sessionClosedSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('session_closed')
        .listen(_handleSessionClosed, onError: _handleEventError);

    _playerResultsSubscription?.cancel();
    _playerResultsSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>('player_results')
        .listen(_handlePlayerResults, onError: _handleEventError);
  }

  /// Marca bandera para emitir client_ready al reconectar.
  void _markReadyForSync() {
    _shouldEmitClientReady = true;
    _safeEmitClientReady();
  }

  /// Evita perder snapshots; solo emite si el socket está listo.
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

  /// Actualiza snapshot de lobby/estado general.
  void _handleGameStateSync(Map<String, dynamic> payload) {
    try {
      final event = HostLobbyUpdateEvent.fromJson(payload);
      _latestGameState = Map<String, dynamic>.from(payload);
      _applyPlayersFromPayload(event.players);
      _phase = _parsePhase(event.state);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Refresca lobby del host ante cambios de jugadores.
  void _handleHostLobbyUpdate(Map<String, dynamic> payload) {
    try {
      final event = HostLobbyUpdateEvent.fromJson(payload);
      _latestGameState = Map<String, dynamic>.from(payload);
      _applyPlayersFromPayload(event.players);
      _phase = _parsePhase(event.state);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Sincroniza nickname y estado al conectar como jugador.
  void _handlePlayerConnectedToSession(Map<String, dynamic> payload) {
    try {
      final event = PlayerConnectedEvent.fromJson(payload);
      _latestGameState = Map<String, dynamic>.from(payload);
      if (event.nickname.isNotEmpty) {
        _currentNickname = event.nickname;
      }
      _phase = _parsePhase(event.state);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Actualiza contador de respuestas recibidas (host).
  void _handleHostAnswerUpdate(Map<String, dynamic> payload) {
    try {
      final event = HostAnswerUpdateEvent.fromJson(payload);
      _hostAnswerSubmissions = event.numberOfSubmissions;
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Marca al jugador saliente como desconectado sin sacarlo del lobby.
  void _handlePlayerLeftSession(Map<String, dynamic> payload) {
    try {
      final event = PlayerLeftSessionEvent.fromJson(payload);
      _playerLeftEvent = Map<String, dynamic>.from(payload);
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
      _handleEventError(error);
    }
  }

  /// Recibe aviso de que el host abandonó.
  void _handleHostLeftSession(Map<String, dynamic> payload) {
    try {
      HostLeftSessionEvent.fromJson(payload);
      _hostLeftEvent = Map<String, dynamic>.from(payload);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Notifica que el host volvió a la sesión.
  void _handleHostReturnedSession(Map<String, dynamic> payload) {
    try {
      HostReturnedSessionEvent.fromJson(payload);
      _hostReturnedEvent = Map<String, dynamic>.from(payload);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Maneja error de sincronización fatal.
  void _handleSyncError(Map<String, dynamic> payload) {
    try {
      final event = SyncErrorEvent.fromJson(payload);
      _syncErrorEvent = Map<String, dynamic>.from(payload);
      _lastError = event.message ?? 'Sync error';
      _phase = SessionPhase.end;
      _realtime.disconnect();
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Maneja error de conexión y propaga mensaje.
  void _handleConnectionError(Map<String, dynamic> payload) {
    try {
      final event = ConnectionErrorEvent.fromJson(payload);
      _connectionErrorEvent = Map<String, dynamic>.from(payload);
      _lastError = event.message ?? 'Connection error';
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Convierte summaries a entidad local de jugador de sesión y limpia flags de desconexión.
  void _applyPlayersFromPayload(List<SessionPlayerSummary> players) {
    _players = List.unmodifiable(
      players.map((p) => SessionPlayer(playerId: p.playerId, nickname: p.nickname)).toList(),
    );
  }

  /// Traduce string de fase a enum local.
  SessionPhase _parsePhase(dynamic value) {
    final normalized = value?.toString().toLowerCase();
    switch (normalized) {
      case 'question':
      case 'questions':
        return SessionPhase.question;
      case 'results':
        return SessionPhase.results;
      case 'end':
        return SessionPhase.end;
      default:
        return SessionPhase.lobby;
    }
  }

  /// Deduce timestamp de emisión de la pregunta a partir de tiempo restante.
  DateTime _resolveQuestionIssuedAt(Map<String, dynamic> payload, int? timeRemainingMs, int timeLimitSeconds) {
    final remainingMs = timeRemainingMs ?? payload['timeRemainingMs'];
    if (remainingMs is num && timeLimitSeconds > 0) {
      final totalMs = timeLimitSeconds * 1000;
      final elapsedMs = totalMs - remainingMs.toInt();
      final clampedElapsed = elapsedMs.clamp(0, totalMs);
      return DateTime.now().subtract(Duration(milliseconds: clampedElapsed));
    }
    return DateTime.now();
  }

  /// Valida nickname (6-20 chars) y devuelve versión sanitizada; falla si no cumple.
  String _validateNickname(String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.length < 6 || trimmed.length > 20) {
      throw StateError('El nickname debe tener entre 6 y 20 caracteres.');
    }
    return trimmed;
  }

  /// Maneja inicio de pregunta y resetea cachés de fases anteriores.
  void _handleQuestionStarted(Map<String, dynamic> payload) {
    try {
      final event = QuestionStartedEvent.fromJson(payload);
      _questionSequence++;
      _phase = SessionPhase.question;
      _currentQuestionDto = event;
      _currentQuestionEvent = Map<String, dynamic>.from(payload);
      _questionStartedAt = _resolveQuestionIssuedAt(payload, event.timeRemainingMs, event.slide.timeLimitSeconds);
      // Limpiar cachés de otras fases para evitar renders obsoletos.
      _hostResultsEvent = null;
      _hostResultsDto = null;
      _playerResultsEvent = null;
      _playerResultsDto = null;
      _hostGameEndEvent = null;
      _hostGameEndDto = null;
      _playerGameEndEvent = null;
      _playerGameEndDto = null;
      _hostAnswerSubmissions = null;
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Maneja resultados de pregunta enviados al host.
  void _handleHostResults(Map<String, dynamic> payload) {
    try {
      _hostResultsDto = HostResultsEvent.fromJson(payload);
      _phase = SessionPhase.results;
      _hostResultsEvent = Map<String, dynamic>.from(payload);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Maneja resultados de pregunta para el jugador.
  void _handlePlayerResults(Map<String, dynamic> payload) {
    try {
      _playerResultsDto = PlayerResultsEvent.fromJson(payload);
      _phase = SessionPhase.results;
      _playerResultsEvent = Map<String, dynamic>.from(payload);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Maneja evento de cierre final para el host.
  void _handleHostGameEnd(Map<String, dynamic> payload) {
    try {
      _hostGameEndDto = HostGameEndEvent.fromJson(payload);
      _hostGameEndSequence++;
      _phase = SessionPhase.end;
      _hostGameEndEvent = Map<String, dynamic>.from(payload);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Maneja evento de cierre final para el jugador.
  void _handlePlayerGameEnd(Map<String, dynamic> payload) {
    try {
      _playerGameEndDto = PlayerGameEndEvent.fromJson(payload);
      _playerGameEndSequence++;
      _phase = SessionPhase.end;
      _playerGameEndEvent = Map<String, dynamic>.from(payload);
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Maneja evento de sesión cerrada por backend.
  void _handleSessionClosed(Map<String, dynamic> payload) {
    try {
      SessionClosedEvent.fromJson(payload);
      _sessionClosedEvent = Map<String, dynamic>.from(payload);
      _phase = SessionPhase.end;
      notifyListeners();
    } catch (error) {
      _handleEventError(error);
    }
  }

  /// Captura error de parsing/listener y notifica UI.
  void _handleEventError(Object error) {
    _lastError = error.toString();
    notifyListeners();
  }
}