import 'lib/core/config/api_config.dart';

void main() {
  print('Testing API Configuration System\n');

  // Test quizzybackend configuration
  print('=== Testing QuizzyBackend Configuration ===');
  ApiConfigManager.setConfig(BackendType.quizzyBackend, 'quizzy-backend-1-zpvc.onrender.com');
  print('HTTP Base URL: ${ApiConfigManager.httpBaseUrl}');
  print('WebSocket Base URL: ${ApiConfigManager.websocketBaseUrl}');
  print('Expected HTTP: https://quizzy-backend-1-zpvc.onrender.com/api');
  print('Expected WS: wss://quizzy-backend-1-zpvc.onrender.com');
  print('');

  // Test backcomun configuration
  print('=== Testing BackComun Configuration ===');
  ApiConfigManager.setConfig(BackendType.backcomun, 'backcomun-mzvy.onrender.com');
  print('HTTP Base URL: ${ApiConfigManager.httpBaseUrl}');
  print('WebSocket Base URL: ${ApiConfigManager.websocketBaseUrl}');
  print('Expected HTTP: https://backcomun-mzvy.onrender.com');
  print('Expected WS: wss://backcomun-mzvy.onrender.com');
  print('');

  // Test domain detection logic
  print('=== Testing Domain Detection ===');
  testDomainDetection('https://quizzy-backend-1-zpvc.onrender.com', BackendType.quizzyBackend);
  testDomainDetection('https://backcomun-mzvy.onrender.com', BackendType.backcomun);
  testDomainDetection('https://unknown-domain.com', BackendType.backcomun); // Should default to backcomun
}

void testDomainDetection(String fullUrl, BackendType expectedType) {
  final url = Uri.parse(fullUrl);
  final domain = '${url.host}${url.hasPort ? ':${url.port}' : ''}';

  BackendType detectedType;
  if (domain.contains('quizzy-backend')) {
    detectedType = BackendType.quizzyBackend;
  } else if (domain.contains('backcomun')) {
    detectedType = BackendType.backcomun;
  } else {
    detectedType = BackendType.backcomun; // Default
  }

  print('URL: $fullUrl');
  print('Domain: $domain');
  print('Expected: $expectedType');
  print('Detected: $detectedType');
  print('Match: ${detectedType == expectedType ? '✓' : '✗'}');
  print('');
}
