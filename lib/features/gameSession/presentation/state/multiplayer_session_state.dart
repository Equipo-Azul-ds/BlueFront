import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';

/// Fases de la sesión para renderizado/navegación en UI.
enum SessionPhase { lobby, question, results, end }

/// Jugador en lobby o leaderboard básico (sin métricas de juego).
class SessionPlayer {
  const SessionPlayer({
    required this.playerId,
    required this.nickname,
    this.isDisconnected = false,
  });

  final String playerId;
  final String nickname;
  final bool isDisconnected;

  factory SessionPlayer.fromJson(Map<String, dynamic> json) {
    final idValue = json['playerId']?.toString() ?? '';
    final nicknameValue = json['nickname']?.toString() ?? 'Jugador';
    return SessionPlayer(playerId: idValue, nickname: nicknameValue);
  }

  factory SessionPlayer.fromSummary(SessionPlayerSummary summary) {
    return SessionPlayer(
      playerId: summary.playerId,
      nickname: summary.nickname,
    );
  }

  SessionPlayer markDisconnected() => SessionPlayer(
        playerId: playerId,
        nickname: nickname,
        isDisconnected: true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionPlayer &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          nickname == other.nickname &&
          isDisconnected == other.isDisconnected;

  @override
  int get hashCode => Object.hash(playerId, nickname, isDisconnected);
}

/// Contenedor inmutable para datos relacionados con el lobby.
class LobbyState {
  const LobbyState({
    this.hostSession,
    this.currentPin,
    this.currentNickname,
    this.currentRole,
    this.players = const [],
    this.latestGameStateDto,
    this.isCreatingSession = false,
    this.isJoiningSession = false,
    this.isResolvingQr = false,
  });

  final CreateSessionResponse? hostSession;
  final String? currentPin;
  final String? currentNickname;
  final MultiplayerRole? currentRole;
  final List<SessionPlayer> players;
  final HostLobbyUpdateEvent? latestGameStateDto;
  final bool isCreatingSession;
  final bool isJoiningSession;
  final bool isResolvingQr;

  /// El PIN de la sesión (del PIN actual o respuesta de sesión del anfitrión).
  String? get sessionPin => currentPin ?? hostSession?.sessionPin;

  /// Token QR para unirse mediante escaneo de código QR.
  String? get qrToken => hostSession?.qrToken;

  /// Título del quiz desde la sesión del anfitrión.
  String? get quizTitle => hostSession?.quizTitle;

  /// URL de imagen de portada desde la sesión del anfitrión.
  String? get coverImageUrl => hostSession?.coverImageUrl;

  LobbyState copyWith({
    CreateSessionResponse? hostSession,
    String? currentPin,
    String? currentNickname,
    MultiplayerRole? currentRole,
    List<SessionPlayer>? players,
    HostLobbyUpdateEvent? latestGameStateDto,
    bool? isCreatingSession,
    bool? isJoiningSession,
    bool? isResolvingQr,
    bool clearHostSession = false,
    bool clearCurrentPin = false,
    bool clearCurrentNickname = false,
    bool clearCurrentRole = false,
    bool clearLatestGameState = false,
  }) {
    return LobbyState(
      hostSession: clearHostSession ? null : (hostSession ?? this.hostSession),
      currentPin: clearCurrentPin ? null : (currentPin ?? this.currentPin),
      currentNickname: clearCurrentNickname ? null : (currentNickname ?? this.currentNickname),
      currentRole: clearCurrentRole ? null : (currentRole ?? this.currentRole),
      players: players ?? this.players,
      latestGameStateDto: clearLatestGameState ? null : (latestGameStateDto ?? this.latestGameStateDto),
      isCreatingSession: isCreatingSession ?? this.isCreatingSession,
      isJoiningSession: isJoiningSession ?? this.isJoiningSession,
      isResolvingQr: isResolvingQr ?? this.isResolvingQr,
    );
  }

  /// Crea un estado reiniciado, opcionalmente limpiando datos de la sesión del anfitrión.
  LobbyState reset({bool clearHostSession = false}) {
    if (clearHostSession) {
      return const LobbyState();
    }
    return LobbyState(
      hostSession: hostSession,
      currentPin: currentPin,
      currentNickname: currentNickname,
      currentRole: currentRole,
    );
  }

  static const LobbyState initial = LobbyState();
}

/// Contenedor inmutable de estado para datos relacionados con la jugabilidad.
class GameplayState {
  const GameplayState({
    this.phase = SessionPhase.lobby,
    this.currentQuestionDto,
    this.questionStartedAt,
    this.questionSequence = 0,
    this.hostAnswerSubmissions,
    this.hostResultsDto,
    this.playerResultsDto,
    this.hostGameEndDto,
    this.hostGameEndSequence = 0,
    this.playerGameEndDto,
    this.playerGameEndSequence = 0,
  });

  final SessionPhase phase;
  final QuestionStartedEvent? currentQuestionDto;
  final DateTime? questionStartedAt;
  final int questionSequence;
  final int? hostAnswerSubmissions;
  final HostResultsEvent? hostResultsDto;
  final PlayerResultsEvent? playerResultsDto;
  final HostGameEndEvent? hostGameEndDto;
  final int hostGameEndSequence;
  final PlayerGameEndEvent? playerGameEndDto;
  final int playerGameEndSequence;

  GameplayState copyWith({
    SessionPhase? phase,
    QuestionStartedEvent? currentQuestionDto,
    DateTime? questionStartedAt,
    int? questionSequence,
    int? hostAnswerSubmissions,
    HostResultsEvent? hostResultsDto,
    PlayerResultsEvent? playerResultsDto,
    HostGameEndEvent? hostGameEndDto,
    int? hostGameEndSequence,
    PlayerGameEndEvent? playerGameEndDto,
    int? playerGameEndSequence,
    bool clearCurrentQuestion = false,
    bool clearQuestionStartedAt = false,
    bool clearHostAnswerSubmissions = false,
    bool clearHostResults = false,
    bool clearPlayerResults = false,
    bool clearHostGameEnd = false,
    bool clearPlayerGameEnd = false,
  }) {
    return GameplayState(
      phase: phase ?? this.phase,
      currentQuestionDto: clearCurrentQuestion ? null : (currentQuestionDto ?? this.currentQuestionDto),
      questionStartedAt: clearQuestionStartedAt ? null : (questionStartedAt ?? this.questionStartedAt),
      questionSequence: questionSequence ?? this.questionSequence,
      hostAnswerSubmissions: clearHostAnswerSubmissions ? null : (hostAnswerSubmissions ?? this.hostAnswerSubmissions),
      hostResultsDto: clearHostResults ? null : (hostResultsDto ?? this.hostResultsDto),
      playerResultsDto: clearPlayerResults ? null : (playerResultsDto ?? this.playerResultsDto),
      hostGameEndDto: clearHostGameEnd ? null : (hostGameEndDto ?? this.hostGameEndDto),
      hostGameEndSequence: hostGameEndSequence ?? this.hostGameEndSequence,
      playerGameEndDto: clearPlayerGameEnd ? null : (playerGameEndDto ?? this.playerGameEndDto),
      playerGameEndSequence: playerGameEndSequence ?? this.playerGameEndSequence,
    );
  }

  /// Reinicia el estado del juego mientras preserva secuencias si es necesario.
  GameplayState reset() {
    return const GameplayState();
  }

  /// Crea un nuevo estado para cuando comienza una pregunta, limpiando datos de fases anteriores.
  GameplayState onQuestionStarted({
    required QuestionStartedEvent question,
    required DateTime issuedAt,
    required int newSequence,
  }) {
    return GameplayState(
      phase: SessionPhase.question,
      currentQuestionDto: question,
      questionStartedAt: issuedAt,
      questionSequence: newSequence,
      hostAnswerSubmissions: null,
      hostResultsDto: null,
      playerResultsDto: null,
      hostGameEndDto: null,
      hostGameEndSequence: hostGameEndSequence,
      playerGameEndDto: null,
      playerGameEndSequence: playerGameEndSequence,
    );
  }

  static const GameplayState initial = GameplayState();
}

/// Contenedor inmutable de estado para el ciclo de vida de la sesión.
class SessionLifecycleState {
  const SessionLifecycleState({
    this.socketStatus = MultiplayerSocketStatus.idle,
    this.lastError,
    this.sessionClosedDto,
    this.playerLeftDto,
    this.hostLeftDto,
    this.hostReturnedDto,
    this.syncErrorDto,
    this.connectionErrorDto,
    this.hostConnectedSuccessDto,
    this.playerAnswerConfirmationDto,
    this.gameErrorDto,
    this.unavailableSessionDto,
    this.shouldEmitClientReady = false,
  });

  final MultiplayerSocketStatus socketStatus;
  final String? lastError;
  final SessionClosedEvent? sessionClosedDto;
  final PlayerLeftSessionEvent? playerLeftDto;
  final HostLeftSessionEvent? hostLeftDto;
  final HostReturnedSessionEvent? hostReturnedDto;
  final SyncErrorEvent? syncErrorDto;
  final ConnectionErrorEvent? connectionErrorDto;
  final HostConnectedSuccessEvent? hostConnectedSuccessDto;
  final PlayerAnswerConfirmationEvent? playerAnswerConfirmationDto;
  final GameErrorEvent? gameErrorDto;
  final UnavailableSessionEvent? unavailableSessionDto;
  final bool shouldEmitClientReady;

  /// Cuando el socket está conectado.
  bool get isConnected => socketStatus == MultiplayerSocketStatus.connected;

  /// Cuando hay un evento de terminación de sesión (sesión cerrada o host salió).
  bool get hasTerminationEvent => sessionClosedDto != null || hostLeftDto != null;

  SessionLifecycleState copyWith({
    MultiplayerSocketStatus? socketStatus,
    String? lastError,
    SessionClosedEvent? sessionClosedDto,
    PlayerLeftSessionEvent? playerLeftDto,
    HostLeftSessionEvent? hostLeftDto,
    HostReturnedSessionEvent? hostReturnedDto,
    SyncErrorEvent? syncErrorDto,
    ConnectionErrorEvent? connectionErrorDto,
    HostConnectedSuccessEvent? hostConnectedSuccessDto,
    PlayerAnswerConfirmationEvent? playerAnswerConfirmationDto,
    GameErrorEvent? gameErrorDto,
    UnavailableSessionEvent? unavailableSessionDto,
    bool? shouldEmitClientReady,
    bool clearLastError = false,
    bool clearSessionClosed = false,
    bool clearPlayerLeft = false,
    bool clearHostLeft = false,
    bool clearHostReturned = false,
    bool clearSyncError = false,
    bool clearConnectionError = false,
    bool clearHostConnectedSuccess = false,
    bool clearPlayerAnswerConfirmation = false,
    bool clearGameError = false,
    bool clearUnavailableSession = false,
  }) {
    return SessionLifecycleState(
      socketStatus: socketStatus ?? this.socketStatus,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      sessionClosedDto: clearSessionClosed ? null : (sessionClosedDto ?? this.sessionClosedDto),
      playerLeftDto: clearPlayerLeft ? null : (playerLeftDto ?? this.playerLeftDto),
      hostLeftDto: clearHostLeft ? null : (hostLeftDto ?? this.hostLeftDto),
      hostReturnedDto: clearHostReturned ? null : (hostReturnedDto ?? this.hostReturnedDto),
      syncErrorDto: clearSyncError ? null : (syncErrorDto ?? this.syncErrorDto),
      connectionErrorDto: clearConnectionError ? null : (connectionErrorDto ?? this.connectionErrorDto),
      hostConnectedSuccessDto: clearHostConnectedSuccess ? null : (hostConnectedSuccessDto ?? this.hostConnectedSuccessDto),
      playerAnswerConfirmationDto: clearPlayerAnswerConfirmation ? null : (playerAnswerConfirmationDto ?? this.playerAnswerConfirmationDto),
      gameErrorDto: clearGameError ? null : (gameErrorDto ?? this.gameErrorDto),
      unavailableSessionDto: clearUnavailableSession ? null : (unavailableSessionDto ?? this.unavailableSessionDto),
      shouldEmitClientReady: shouldEmitClientReady ?? this.shouldEmitClientReady,
    );
  }

  SessionLifecycleState reset() {
    return SessionLifecycleState(
      socketStatus: socketStatus,
    );
  }

  static const SessionLifecycleState initial = SessionLifecycleState();
}

/// Estado immutable contenedor para toda la sesión multijugador.
class MultiplayerSessionSnapshot {
  const MultiplayerSessionSnapshot({
    this.lobby = LobbyState.initial,
    this.gameplay = GameplayState.initial,
    this.lifecycle = SessionLifecycleState.initial,
  });

  final LobbyState lobby;
  final GameplayState gameplay;
  final SessionLifecycleState lifecycle;

  MultiplayerSessionSnapshot copyWith({
    LobbyState? lobby,
    GameplayState? gameplay,
    SessionLifecycleState? lifecycle,
  }) {
    return MultiplayerSessionSnapshot(
      lobby: lobby ?? this.lobby,
      gameplay: gameplay ?? this.gameplay,
      lifecycle: lifecycle ?? this.lifecycle,
    );
  }

  /// Full reset del estado de la sesión.
  MultiplayerSessionSnapshot reset({bool clearHostSession = false}) {
    return MultiplayerSessionSnapshot(
      lobby: lobby.reset(clearHostSession: clearHostSession),
      gameplay: gameplay.reset(),
      lifecycle: lifecycle.reset(),
    );
  }

  static const MultiplayerSessionSnapshot initial = MultiplayerSessionSnapshot();
}
