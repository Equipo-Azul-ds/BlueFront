/// Centralized socket event names for the multiplayer game session feature.
/// 
/// Using constants prevents typos and makes it easier to track all events
/// used across the codebase.
abstract class MultiplayerEvents {
  // ─────────────────────────────────────────────────────────────────────────
  // Client → Server events (emitted by client)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Signals the server that the client is ready to receive sync events.
  static const String clientReady = 'client_ready';
  
  /// Player requests to join a lobby with their nickname.
  static const String playerJoin = 'player_join';
  
  /// Host signals to start the game.
  static const String hostStartGame = 'host_start_game';
  
  /// Player submits their answer for the current question.
  static const String playerSubmitAnswer = 'player_submit_answer';
  
  /// Host advances to the next phase (results or next question).
  static const String hostNextPhase = 'host_next_phase';
  
  /// Host ends the session and disconnects all players.
  static const String hostEndSession = 'host_end_session';

  // ─────────────────────────────────────────────────────────────────────────
  // Server → Client events (listened by client)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// General game state sync (lobby state, players, etc.).
  static const String gameStateUpdate = 'game_state_update';
  
  /// Host receives lobby updates (player list changes).
  static const String hostLobbyUpdate = 'host_lobby_update';
  
  /// Player receives confirmation of connection with initial state.
  static const String playerConnectedToSession = 'player_connected_to_session';
  
  /// Host receives count of submitted answers during a question.
  static const String hostAnswerUpdate = 'host_answer_update';
  
  /// Notification that a player left the session.
  static const String playerLeftSession = 'player_left_session';
  
  /// Notification to players that the host left.
  static const String hostLeftSession = 'host_left_session';
  
  /// Notification to players that the host returned.
  static const String hostReturnedToSession = 'host_returned_to_session';
  
  /// Fatal sync error from server (usually closes session).
  static const String syncError = 'sync_error';
  
  /// Connection-level error for the client.
  static const String connectionError = 'connection_error';
  
  /// A new question has started (contains slide data and time).
  static const String questionStarted = 'question_started';
  
  /// Host receives question results (leaderboard, stats).
  static const String hostResults = 'host_results';
  
  /// Host receives final game end event (podium, winner).
  static const String hostGameEnd = 'host_game_end';
  
  /// Player receives their final game summary.
  static const String playerGameEnd = 'player_game_end';
  
  /// Session was closed by the server.
  static const String sessionClosed = 'session_closed';
  
  /// Player receives their results for the current question.
  static const String playerResults = 'player_results';
  
  /// Host receives confirmation of successful connection to the room.
  static const String hostConnectedSuccess = 'host_connected_success';
  
  /// Player receives confirmation that their answer was submitted.
  static const String playerAnswerConfirmation = 'player_answer_confirmation';
  
  /// Error response for invalid game commands (e.g., wrong phase, unauthorized).
  static const String gameError = 'game_error';
}
