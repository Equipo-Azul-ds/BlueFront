import 'lib/core/config/api_config.dart';

// Simulate the main.dart initialization logic
void main() {
  print('Testing Main.dart API Configuration Initialization\n');

  // Test with quizzybackend URL
  print('=== Testing with QuizzyBackend URL ===');
  const quizzyUrl = 'https://quizzy-backend-1-zpvc.onrender.com';
  _initializeApiConfig(quizzyUrl);
  print('Input URL: $quizzyUrl');
  print('HTTP Base URL: ${ApiConfigManager.httpBaseUrl}');
  print('WebSocket Base URL: ${ApiConfigManager.websocketBaseUrl}');
  print('');

  // Test with backcomun URL
  print('=== Testing with BackComun URL ===');
  const backcomunUrl = 'https://backcomun-mzvy.onrender.com';
  _initializeApiConfig(backcomunUrl);
  print('Input URL: $backcomunUrl');
  print('HTTP Base URL: ${ApiConfigManager.httpBaseUrl}');
  print('WebSocket Base URL: ${ApiConfigManager.websocketBaseUrl}');
  print('');

  // Test with unknown domain (should default to backcomun)
  print('=== Testing with Unknown Domain ===');
  const unknownUrl = 'https://unknown-backend.com';
  _initializeApiConfig(unknownUrl);
  print('Input URL: $unknownUrl');
  print('HTTP Base URL: ${ApiConfigManager.httpBaseUrl}');
  print('WebSocket Base URL: ${ApiConfigManager.websocketBaseUrl}');
  print('');
}

/// Simulates the _initializeApiConfig function from main.dart
void _initializeApiConfig(String apiBaseUrl) {
  // Extract domain from the full URL
  final url = Uri.parse(apiBaseUrl);
  final domain = '${url.host}${url.hasPort ? ':${url.port}' : ''}';

  // Determine backend type based on domain
  if (domain.contains('quizzy-backend')) {
    ApiConfigManager.setConfig(BackendType.quizzyBackend, domain);
  } else if (domain.contains('backcomun')) {
    ApiConfigManager.setConfig(BackendType.backcomun, domain);
  } else {
    // Default to backcomun if unrecognized
    ApiConfigManager.setConfig(BackendType.backcomun, domain);
  }
}
