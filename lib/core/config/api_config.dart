/// Configuration for API endpoints supporting multiple backends.
/// Handles URL construction differences between backends for HTTP and WebSocket connections.
class ApiConfig {
  const ApiConfig._({
    required this.httpBaseUrl,
    required this.websocketBaseUrl,
  });

  /// Factory for quizzybackend configuration.
  /// HTTP requests use /api suffix, WebSocket uses wss:// protocol.
  factory ApiConfig.quizzyBackend(String baseDomain) {
    final httpUrl = 'https://$baseDomain/api';
    final wsUrl = 'wss://$baseDomain';
    return ApiConfig._(
      httpBaseUrl: httpUrl,
      websocketBaseUrl: wsUrl,
    );
  }

  /// Factory for backcomun configuration.
  /// HTTP requests use no suffix, WebSocket uses wss:// protocol.
  factory ApiConfig.backcomun(String baseDomain) {
    final httpUrl = 'https://$baseDomain';
    final wsUrl = 'wss://$baseDomain';
    return ApiConfig._(
      httpBaseUrl: httpUrl,
      websocketBaseUrl: wsUrl,
    );
  }

  final String httpBaseUrl;
  final String websocketBaseUrl;

  /// Returns the appropriate base URL for HTTP requests.
  String getHttpUrl() => httpBaseUrl;

  /// Returns the appropriate base URL for WebSocket connections.
  String getWebSocketUrl() => websocketBaseUrl;

  /// Builds a complete HTTP endpoint URL.
  String buildHttpUrl(String path) {
    final base = httpBaseUrl.endsWith('/') ? httpBaseUrl : '$httpBaseUrl/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$base$cleanPath';
  }

  /// Builds a complete WebSocket namespace URL.
  String buildWebSocketUrl(String namespace) {
    final base = websocketBaseUrl.endsWith('/') ? websocketBaseUrl : '$websocketBaseUrl/';
    final cleanNamespace = namespace.startsWith('/') ? namespace.substring(1) : namespace;
    return '$base$cleanNamespace';
  }
}

/// Enum to identify available backends.
enum BackendType {
  quizzyBackend,
  backcomun,
}

/// Central configuration manager for API backends.
class ApiConfigManager {
  static ApiConfig? _currentConfig;

  /// Sets the current backend configuration.
  static void setConfig(BackendType backend, String baseDomain) {
    switch (backend) {
      case BackendType.quizzyBackend:
        _currentConfig = ApiConfig.quizzyBackend(baseDomain);
        break;
      case BackendType.backcomun:
        _currentConfig = ApiConfig.backcomun(baseDomain);
        break;
    }
  }

  /// Gets the current API configuration.
  /// Throws if no configuration has been set.
  static ApiConfig get current {
    if (_currentConfig == null) {
      throw StateError('API configuration not set. Call setConfig() first.');
    }
    return _currentConfig!;
  }

  /// Convenience getter for HTTP base URL (for backward compatibility).
  static String get httpBaseUrl => current.getHttpUrl();

  /// Convenience getter for WebSocket base URL.
  static String get websocketBaseUrl => current.getWebSocketUrl();
}
