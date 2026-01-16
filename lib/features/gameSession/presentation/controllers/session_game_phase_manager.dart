import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import '../state/multiplayer_session_state.dart';
import 'base_session_manager.dart';

/// Gestiona el estado de fase del juego y transiciones.
/// Responsabilidades: flujo de preguntas, resultados, fin de juego, transiciones de fase.
class SessionGamePhaseManager extends BaseSessionManager {
  SessionGamePhaseManager({
    required MultiplayerSessionRealtime realtime,
  }) : super(realtime: realtime);

  SessionPhase _phase = SessionPhase.lobby;
  QuestionStartedEvent? _currentQuestionDto;
  HostResultsEvent? _hostResultsDto;
  PlayerResultsEvent? _playerResultsDto;
  HostGameEndEvent? _hostGameEndDto;
  PlayerGameEndEvent? _playerGameEndDto;
  SessionClosedEvent? _sessionClosedDto;
  DateTime? _questionStartedAt;
  int _questionSequence = 0;
  int _hostGameEndSequence = 0;
  int _playerGameEndSequence = 0;
  int? _hostAnswerSubmissions;

  // Getters
  SessionPhase get phase => _phase;
  QuestionStartedEvent? get currentQuestionDto => _currentQuestionDto;
  HostResultsEvent? get hostResultsDto => _hostResultsDto;
  PlayerResultsEvent? get playerResultsDto => _playerResultsDto;
  HostGameEndEvent? get hostGameEndDto => _hostGameEndDto;
  PlayerGameEndEvent? get playerGameEndDto => _playerGameEndDto;
  SessionClosedEvent? get sessionClosedDto => _sessionClosedDto;
  DateTime? get questionStartedAt => _questionStartedAt;
  int get questionSequence => _questionSequence;
  int get hostGameEndSequence => _hostGameEndSequence;
  int get playerGameEndSequence => _playerGameEndSequence;
  int? get hostAnswerSubmissions => _hostAnswerSubmissions;

  /// Establece la fase actual del juego.
  void setPhase(SessionPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  /// Actualiza el conteo de respuestas enviadas por el anfitrión.
  void setHostAnswerSubmissions(int? count) {
    _hostAnswerSubmissions = count;
    notifyListeners();
  }
  /// Registra oyentes para eventos de fase de juego.
  void registerGamePhaseListeners(
    void Function(Object error) onEventError,
  ) {
    registerEventListener<QuestionStartedEvent>(
      eventName: MultiplayerEvents.questionStarted,
      parser: (payload) => QuestionStartedEvent.fromJson(payload),
      handler: _handleQuestionStarted,
      onError: onEventError,
    );

    registerEventListener<HostResultsEvent>(
      eventName: MultiplayerEvents.hostResults,
      parser: (payload) => HostResultsEvent.fromJson(payload),
      handler: _handleHostResults,
      onError: onEventError,
    );

    registerEventListener<PlayerResultsEvent>(
      eventName: MultiplayerEvents.playerResults,
      parser: (payload) => PlayerResultsEvent.fromJson(payload),
      handler: _handlePlayerResults,
      onError: onEventError,
    );

    registerEventListener<HostGameEndEvent>(
      eventName: MultiplayerEvents.hostGameEnd,
      parser: (payload) => HostGameEndEvent.fromJson(payload),
      handler: _handleHostGameEnd,
      onError: onEventError,
    );

    registerEventListener<PlayerGameEndEvent>(
      eventName: MultiplayerEvents.playerGameEnd,
      parser: (payload) => PlayerGameEndEvent.fromJson(payload),
      handler: _handlePlayerGameEnd,
      onError: onEventError,
    );

    registerEventListener<SessionClosedEvent>(
      eventName: MultiplayerEvents.sessionClosed,
      parser: (payload) => SessionClosedEvent.fromJson(payload),
      handler: _handleSessionClosed,
      onError: onEventError,
    );

    registerEventListener<HostAnswerUpdateEvent>(
      eventName: MultiplayerEvents.hostAnswerUpdate,
      parser: (payload) => HostAnswerUpdateEvent.fromJson(payload),
      handler: _handleHostAnswerUpdate,
      onError: onEventError,
    );

    // Some servers send the pluralized event name 'host_answers_update'. Listen
    // to both forms to be robust against backend naming variations.
    registerEventListener<HostAnswerUpdateEvent>(
      eventName: 'host_answers_update',
      parser: (payload) => HostAnswerUpdateEvent.fromJson(payload),
      handler: _handleHostAnswerUpdate,
      onError: onEventError,
    );

    // Also listen to player answer confirmations to update the submissions counter
    registerEventListener<PlayerAnswerConfirmationEvent>(
      eventName: MultiplayerEvents.playerAnswerConfirmation,
      parser: (payload) => PlayerAnswerConfirmationEvent.fromJson(payload),
      handler: _handlePlayerAnswerConfirmation,
      onError: onEventError,
    );
  }

  /// Maneja evento de pregunta iniciada.
  void _handleQuestionStarted(QuestionStartedEvent event) {
    _questionSequence++;
    print('[EVENT] ← RECEIVED: question_started (seq=$_questionSequence, questionId=${event.slide.id}, timeLimit=${event.slide.timeLimitSeconds}s)');
    _phase = SessionPhase.question;
    _currentQuestionDto = event;
    _questionStartedAt =
        _resolveQuestionIssuedAt(event.timeRemainingMs, event.slide.timeLimitSeconds);
    _hostResultsDto = null;
    _playerResultsDto = null;
    _hostGameEndDto = null;
    _playerGameEndDto = null;
    _hostAnswerSubmissions = null;
  }

  /// Maneja evento de resultados del anfitrión.
  void _handleHostResults(HostResultsEvent event) {
    _hostResultsDto = event;
    print('[EVENT] ← RECEIVED: host_results (state=${_hostResultsDto?.state}, players=${_hostResultsDto?.leaderboard.length})');
    _phase = SessionPhase.results;
  }

  /// Maneja evento de resultados del jugador.
  void _handlePlayerResults(PlayerResultsEvent event) {
    _playerResultsDto = event;
    print('[EVENT] ← RECEIVED: player_results (rank=${_playerResultsDto?.rank}, correct=${_playerResultsDto?.isCorrect})');
    _phase = SessionPhase.results;
  }

  /// Maneja evento de fin de juego del anfitrión.
  void _handleHostGameEnd(HostGameEndEvent event) {
    _hostGameEndDto = event;
    _hostGameEndSequence++;
    print('[EVENT] ← RECEIVED: host_game_end (seq=$_hostGameEndSequence, podium=${_hostGameEndDto?.finalPodium.length})');
    _phase = SessionPhase.end;
  }

  /// Maneja evento de fin de juego del jugador.
  void _handlePlayerGameEnd(PlayerGameEndEvent event) {
    _playerGameEndDto = event;
    _playerGameEndSequence++;
    print('[EVENT] ← RECEIVED: player_game_end (seq=$_playerGameEndSequence, rank=${_playerGameEndDto?.rank})');
    _phase = SessionPhase.end;
  }

  /// Maneja evento de sesión cerrada.
  void _handleSessionClosed(SessionClosedEvent event) {
    print('[EVENT] ← RECEIVED: session_closed (reason=${event.reason}, message=${event.message})');
    _sessionClosedDto = event;
    _phase = SessionPhase.end;
  }

  /// Maneja evento de actualización de respuestas del host.
  void _handleHostAnswerUpdate(HostAnswerUpdateEvent event) {
    print('[EVENT] ← RECEIVED: host_answer_update (numberOfSubmissions=${event.numberOfSubmissions})');
    // Use setter to ensure listeners are notified and UI updates accordingly
    setHostAnswerSubmissions(event.numberOfSubmissions);
    // Extra debug: dump current question and socket state for correlation
    print('[EVENT]    currentQuestionId=${_currentQuestionDto?.slide.id}, socketConnected=${realtime.isConnected}');
  }

  /// Maneja evento de confirmación de respuesta de un jugador (emitted when a single
  /// player's answer is received). We increment the host submissions counter
  /// optimistically to reflect incoming answers quickly in the UI.
  void _handlePlayerAnswerConfirmation(PlayerAnswerConfirmationEvent event) {
    print('[EVENT] ← RECEIVED: player_answer_confirmation (received=${event.received}, message=${event.message})');
    final current = _hostAnswerSubmissions ?? 0;
    setHostAnswerSubmissions(current + 1);
  }

  /// Resuelve la hora en que se emitió la pregunta basada en el tiempo restante.
  ///
  /// Nota: `timeRemainingMs` es opcional en la API y **si no está presente**
  /// asumimos que la pregunta fue emitida ahora (evita que el temporizador quede a 0)
  /// y que no se dispare una autocaptura de respuesta por timeout inmediatamente.
  DateTime _resolveQuestionIssuedAt(int? timeRemainingMs, int timeLimitSeconds) {
    if (timeRemainingMs == null) {
      print('[EVENT] ⚠ RECEIVED: question_started without timeRemainingMs — assuming just-issued (no elapsed).');
      return DateTime.now();
    }

    final elapsedMs = (timeLimitSeconds * 1000) - timeRemainingMs;
    return DateTime.now().subtract(Duration(milliseconds: elapsedMs));
  }

  /// Reinicia el estado de la fase del juego.
  void resetGamePhaseState() {
    _phase = SessionPhase.lobby;
    _currentQuestionDto = null;
    _hostResultsDto = null;
    _playerResultsDto = null;
    _hostGameEndDto = null;
    _playerGameEndDto = null;
    _sessionClosedDto = null;
    _questionStartedAt = null;
    _questionSequence = 0;
    _hostGameEndSequence = 0;
    _playerGameEndSequence = 0;
    _hostAnswerSubmissions = null;
    notifyListeners();
  }

  /// Limpia datos de resultados del anfitrión.
  void clearHostResults() {
    _hostResultsDto = null;
    notifyListeners();
  }

  /// Limpia datos de resultados del jugador.
  void clearPlayerResults() {
    _playerResultsDto = null;
    notifyListeners();
  }

  /// Limpia datos de fin de juego del anfitrión.
  void clearHostGameEnd() {
    _hostGameEndDto = null;
    notifyListeners();
  }

  /// Limpia datos de fin de juego del jugador.
  void clearPlayerGameEnd() {
    _playerGameEndDto = null;
    notifyListeners();
  }

  /// Limpia datos de sesión cerrada.
  void clearSessionClosed() {
    _sessionClosedDto = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelAllEventListeners();
    super.dispose();
  }
}