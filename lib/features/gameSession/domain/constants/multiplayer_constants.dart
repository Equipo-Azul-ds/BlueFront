/// Centralized constants for the multiplayer game session feature.
/// 
/// Contains validation rules, timeouts, and other magic numbers used
/// throughout the multiplayer session logic.
abstract class MultiplayerConstants {
  // ─────────────────────────────────────────────────────────────────────────
  // Nickname validation
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Minimum allowed nickname length.
  static const int nicknameMinLength = 6;
  
  /// Maximum allowed nickname length.
  static const int nicknameMaxLength = 20;

  // ─────────────────────────────────────────────────────────────────────────
  // Socket connection
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Timeout in milliseconds for socket handshake completion.
  static const int socketHandshakeTimeoutMs = 10000;
  
  /// Transport protocols used for socket connection.
  static const List<String> socketTransports = ['websocket'];

  // ─────────────────────────────────────────────────────────────────────────
  // Default fallback values
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Default player nickname when none is provided.
  static const String defaultNickname = 'Jugador';
  
  /// Default phase state string.
  static const String defaultPhaseState = 'lobby';
  
  /// Default question phase state string.
  static const String questionPhaseState = 'question';
  
  /// Default results phase state string.
  static const String resultsPhaseState = 'results';
  
  /// Default end phase state string.
  static const String endPhaseState = 'end';

  // ─────────────────────────────────────────────────────────────────────────
  // Header keys
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Header key for session PIN.
  static const String headerPin = 'pin';
  
  /// Header key for client role.
  static const String headerRole = 'role';
  
  /// Header key for JWT token.
  static const String headerJwt = 'jwt';
  
  /// Header key for authorization (capitalized).
  static const String headerAuthorization = 'Authorization';
  
  /// Header key for authorization (lowercase).
  static const String headerAuthorizationLower = 'authorization';

  // ─────────────────────────────────────────────────────────────────────────
  // Error messages
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Error message when JWT is missing or invalid.
  static const String errorMissingJwt = 
      'A valid JWT is required to open the multiplayer socket.';
  
  /// Error message when session PIN is missing from response.
  static const String errorMissingSessionPin = 
      'El backend no devolvió un PIN de sesión válido.';
  
  /// Error message for invalid nickname length.
  static String errorInvalidNickname(int min, int max) =>
      'El nickname debe tener entre $min y $max caracteres.';
  
  /// Default sync error message.
  static const String errorSyncDefault = 'Sync error';
  
  /// Default connection error message.
  static const String errorConnectionDefault = 'Connection error';
}
