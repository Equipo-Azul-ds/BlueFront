/// Nombres de eventos de socket centralizados para la característica de sesión de juego multijugador.
/// 
/// El uso de constantes previene errores tipográficos y facilita el seguimiento de todos los eventos
/// utilizados en toda la base de código.
abstract class MultiplayerEvents {
  // ─────────────────────────────────────────────────────────────────────────
  // Cliente → Servidor eventos (emitidos por cliente)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Señala al servidor que el cliente está listo para recibir eventos de sincronización.
  static const String clientReady = 'client_ready';
  
  /// El jugador solicita unirse a un lobby con su apodo.
  static const String playerJoin = 'player_join';
  
  /// El anfitrión señala para iniciar el juego.
  static const String hostStartGame = 'host_start_game';
  
  /// El jugador envía su respuesta para la pregunta actual.
  static const String playerSubmitAnswer = 'player_submit_answer';
  
  /// El anfitrión avanza a la siguiente fase (resultados o siguiente pregunta).
  static const String hostNextPhase = 'host_next_phase';
  
  /// El anfitrión termina la sesión y desconecta a todos los jugadores.
  static const String hostEndSession = 'host_end_session';

  // ─────────────────────────────────────────────────────────────────────────
  // Servidor → Cliente eventos (escuchados por cliente)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Sincronización general de estado del juego (estado del lobby, jugadores, etc.).
  static const String gameStateUpdate = 'game_state_update';
  
  /// El anfitrión recibe actualizaciones del lobby (cambios en la lista de jugadores).
  static const String hostLobbyUpdate = 'host_lobby_update';
  
  /// El jugador recibe confirmación de conexión con estado inicial.
  static const String playerConnectedToSession = 'player_connected_to_session';
  
  /// El anfitrión recibe el conteo de respuestas enviadas durante una pregunta.
  static const String hostAnswerUpdate = 'host_answer_update';
  
  /// Notificación de que un jugador abandonó la sesión.
  static const String playerLeftSession = 'player_left_session';
  
  /// Notificación a los jugadores de que el anfitrión se fue.
  static const String hostLeftSession = 'host_left_session';
  
  /// Notificación a los jugadores de que el anfitrión regresó.
  static const String hostReturnedToSession = 'host_returned_to_session';
  
  /// La sesión solicitada no existe o no está disponible.
  static const String unavailableSession = 'unnavailable_session';
  
  /// Error de sincronización fatal del servidor (generalmente cierra la sesión).
  static const String syncError = 'sync_error';
  
  /// Error a nivel de conexión para el cliente.
  static const String connectionError = 'connection_error';
  
  /// Una nueva pregunta ha comenzado (contiene datos de diapositiva y tiempo).
  static const String questionStarted = 'question_started';
  
  /// El anfitrión recibe resultados de la pregunta (tabla de posiciones, estadísticas).
  static const String hostResults = 'host_results';
  
  /// El anfitrión recibe evento final de fin de juego (podio, ganador).
  static const String hostGameEnd = 'host_game_end';
  
  /// El jugador recibe su resumen final del juego.
  static const String playerGameEnd = 'player_game_end';
  
  /// El servidor cerró la sesión.
  static const String sessionClosed = 'session_closed';
  
  /// El jugador recibe sus resultados para la pregunta actual.
  static const String playerResults = 'player_results';
  
  /// El anfitrión recibe confirmación de conexión exitosa a la sala.
  static const String hostConnectedSuccess = 'host_connected_success';
  
  /// El jugador recibe confirmación de que su respuesta fue enviada.
  static const String playerAnswerConfirmation = 'player_answer_confirmation';
  
  /// Respuesta de error para comandos de juego inválidos (ej: fase incorrecta, no autorizado).
  static const String gameError = 'game_error';
}
