import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import '../state/multiplayer_session_state.dart';


/// Gestiona el estado de fase del juego y transiciones.
/// Responsabilidades: flujo de preguntas, resultados, fin de juego, transiciones de fase.
class SessionGamePhaseManager extends ChangeNotifier {
  SessionGamePhaseManager({
    required MultiplayerSessionRealtime realtime,
  }) : _realtime = realtime;

  final MultiplayerSessionRealtime _realtime;

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

  StreamSubscription<dynamic>? _questionStartedSubscription;
  StreamSubscription<dynamic>? _hostResultsSubscription;
  StreamSubscription<dynamic>? _playerResultsSubscription;
  StreamSubscription<dynamic>? _hostGameEndSubscription;
  StreamSubscription<dynamic>? _playerGameEndSubscription;
  StreamSubscription<dynamic>? _sessionClosedSubscription;

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


  /// Registra oyentes para eventos de fase de juego (pregunta iniciada, resultados, fin de juego, sesión cerrada).
  void registerGamePhaseListeners(
    void Function(Object error) onEventError,
  ) {
    _questionStartedSubscription?.cancel();
    _questionStartedSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.questionStarted)
        .listen(
          (payload) => _handleQuestionStarted(payload, onEventError),
          onError: onEventError,
        );

    _hostResultsSubscription?.cancel();
    _hostResultsSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(MultiplayerEvents.hostResults)
        .listen(
          (payload) => _handleHostResults(payload, onEventError),
          onError: onEventError,
        );

    _playerResultsSubscription?.cancel();
    _playerResultsSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.playerResults)
        .listen(
          (payload) => _handlePlayerResults(payload, onEventError),
          onError: onEventError,
        );

    _hostGameEndSubscription?.cancel();
    _hostGameEndSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(MultiplayerEvents.hostGameEnd)
        .listen(
          (payload) => _handleHostGameEnd(payload, onEventError),
          onError: onEventError,
        );

    _playerGameEndSubscription?.cancel();
    _playerGameEndSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.playerGameEnd)
        .listen(
          (payload) => _handlePlayerGameEnd(payload, onEventError),
          onError: onEventError,
        );

    _sessionClosedSubscription?.cancel();
    _sessionClosedSubscription = _realtime
        .listenToServerEvent<Map<String, dynamic>>(
            MultiplayerEvents.sessionClosed)
        .listen(
          (payload) => _handleSessionClosed(payload, onEventError),
          onError: onEventError,
        );
  }

  /// Maneja evento de pregunta iniciada: incrementa secuencia, actualiza fase, cachea datos de pregunta y limpia resultados obsoletos.
  void _handleQuestionStarted(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = QuestionStartedEvent.fromJson(payload);
      _questionSequence++;
      print('[EVENT] ← RECEIVED: question_started (seq=$_questionSequence, questionId=${event.slide.id}, timeLimit=${event.slide.timeLimitSeconds}s)');
      _phase = SessionPhase.question;
      _currentQuestionDto = event;
      _questionStartedAt =
          _resolveQuestionIssuedAt(event.timeRemainingMs, event.slide.timeLimitSeconds);
      // Limpia cachés de otras fases para evitar renderizaciones obsoletas.
      _hostResultsDto = null;
      _playerResultsDto = null;
      _hostGameEndDto = null;
      _playerGameEndDto = null;
      _hostAnswerSubmissions = null;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing question_started: $error');
      onEventError(error);
    }
  }

  /// Maneja evento de resultados del anfitrión: cachea datos de resultados y transiciona a fase de resultados.
  void _handleHostResults(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      _hostResultsDto = HostResultsEvent.fromJson(payload);
      print('[EVENT] ← RECEIVED: host_results (state=${_hostResultsDto?.state}, players=${_hostResultsDto?.leaderboard.length})');
      _phase = SessionPhase.results;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing host_results: $error');
      onEventError(error);
    }
  }

  /// Maneja evento de resultados del jugador: cachea datos de resultados y transiciona a fase de resultados.
  void _handlePlayerResults(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      _playerResultsDto = PlayerResultsEvent.fromJson(payload);
      print('[EVENT] ← RECEIVED: player_results (rank=${_playerResultsDto?.rank}, correct=${_playerResultsDto?.isCorrect})');
      _phase = SessionPhase.results;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing player_results: $error');
      onEventError(error);
    }
  }

  /// Maneja evento de fin de juego del anfitrión: incrementa secuencia de fin, cachea datos de fin y transiciona a fase de fin.
  void _handleHostGameEnd(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      _hostGameEndDto = HostGameEndEvent.fromJson(payload);
      _hostGameEndSequence++;
      print('[EVENT] ← RECEIVED: host_game_end (seq=$_hostGameEndSequence, podium=${_hostGameEndDto?.finalPodium.length})');
      _phase = SessionPhase.end;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing host_game_end: $error');
      onEventError(error);
    }
  }

  /// Maneja evento de fin de juego del jugador: incrementa secuencia de fin, cachea datos de fin y transiciona a fase de fin.
  void _handlePlayerGameEnd(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      _playerGameEndDto = PlayerGameEndEvent.fromJson(payload);
      _playerGameEndSequence++;
      print('[EVENT] ← RECEIVED: player_game_end (seq=$_playerGameEndSequence, rank=${_playerGameEndDto?.rank})');
      _phase = SessionPhase.end;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing player_game_end: $error');
      onEventError(error);
    }
  }

  /// Maneja evento de sesión cerrada: cachea datos de cierre y transiciona a fase de fin.
  void _handleSessionClosed(
    Map<String, dynamic> payload,
    void Function(Object error) onEventError,
  ) {
    try {
      final event = SessionClosedEvent.fromJson(payload);
      print('[EVENT] ← RECEIVED: session_closed (reason=${event.reason}, message=${event.message})');
      _sessionClosedDto = event;
      _phase = SessionPhase.end;
      notifyListeners();
    } catch (error) {
      print('[EVENT] ✗ ERROR parsing session_closed: $error');
      onEventError(error);
    }
  }

 /// Deduce la marca de tiempo de la pregunta basándose en el tiempo restante y el límite de tiempo.
  DateTime _resolveQuestionIssuedAt(int? timeRemainingMs, int timeLimitSeconds) {
    if (timeRemainingMs != null && timeLimitSeconds > 0) {
      final totalMs = timeLimitSeconds * 1000;
      final elapsedMs = totalMs - timeRemainingMs;
      final clampedElapsed = elapsedMs.clamp(0, totalMs);
      return DateTime.now().subtract(Duration(milliseconds: clampedElapsed));
    }
    return DateTime.now();
  }

 /// Reinicia el estado de la fase del juego a lobby, limpiando todos los datos de pregunta, resultados y fin del juego.
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

 /// Limpia datos de resultados del anfitrión cacheados y notifica a los oyentes.
  void clearHostResults() {
    _hostResultsDto = null;
    notifyListeners();
  }

 /// Limpia datos de resultados del jugador cacheados y notifica a los oyentes.
  void clearPlayerResults() {
    _playerResultsDto = null;
    notifyListeners();
  }

  /// Limpia datos de fin de juego del anfitrión cacheados y notifica a los oyentes.
  void clearHostGameEnd() {
    _hostGameEndDto = null;
    notifyListeners();
  }

   /// Limpia datos de fin de juego del jugador cacheados y notifica a los oyentes.
  void clearPlayerGameEnd() {
    _playerGameEndDto = null;
    notifyListeners();
  }

  /// Limpia datos de sesión cerrada cacheados y notifica a los oyentes.
  void clearSessionClosed() {
    _sessionClosedDto = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _questionStartedSubscription?.cancel();
    _hostResultsSubscription?.cancel();
    _playerResultsSubscription?.cancel();
    _hostGameEndSubscription?.cancel();
    _playerGameEndSubscription?.cancel();
    _sessionClosedSubscription?.cancel();
    super.dispose();
  }
}
