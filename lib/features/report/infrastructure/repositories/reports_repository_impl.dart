import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/report_model.dart';
import '../../domain/repositories/reports_repository.dart';

/// Provides a JWT token (optionally already prefixed with 'Bearer ').
typedef TokenProvider = FutureOr<String?> Function();

/// Custom exception for Reports API errors with status code context.
class ReportsApiException implements Exception {
  ReportsApiException({
    required this.message,
    required this.statusCode,
    required this.path,
  });

  final String message;
  final int statusCode;
  final String path;

  @override
  String toString() => 'ReportsApiException: $message (HTTP $statusCode) - $path';
}

/// Implementación con soporte para auth headers.
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final TokenProvider? tokenProvider;

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    print('🔹 [ReportsRepository] GET request to: $uri');
    final headers = await _buildJsonHeaders();
    print('🔹 [ReportsRepository] Headers: $headers');
    final resp = await _client.get(uri, headers: headers);
    print('🔹 [ReportsRepository] Status Code: ${resp.statusCode}');
    print('🔹 [ReportsRepository] Response body: ${resp.body}');
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        print('✅ [ReportsRepository] Successfully decoded JSON');
        return decoded;
      }
    }
    
    final errorMessage = _getErrorMessageForStatus(resp.statusCode, uri.path);
    print('❌ [ReportsRepository] $errorMessage');
    throw ReportsApiException(
      message: errorMessage,
      statusCode: resp.statusCode,
      path: uri.path,
    );
  }

  Future<Map<String, String>> _buildJsonHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    try {
      final token = await Future.value(tokenProvider?.call());
      if (token != null && token.isNotEmpty) {
        final authValue = RegExp(r'^bearer ', caseSensitive: false).hasMatch(token)
            ? token
            : 'Bearer $token';
        headers['Authorization'] = authValue;
      }
    } catch (e) {
      print('[ReportsRepository] tokenProvider failed: $e');
    }
    return headers;
  }

  String _getErrorMessageForStatus(int statusCode, String path) {
    switch (statusCode) {
      case 401:
        return 'No autenticado: El servidor rechazó tu solicitud de acceso.';
      case 403:
        return 'No autorizado: No tienes permisos para acceder a este recurso.';
      case 404:
        return 'No encontrado: El recurso solicitado no existe.';
      case 500:
      case 502:
      case 503:
        return 'Error del servidor: Intenta más tarde.';
      default:
        return 'Error al consultar $path: HTTP $statusCode';
    }
  }

  @override
  Future<MyResultsResponse> fetchMyResults({int limit = 20, int page = 1}) async {
    final validatedLimit = _validateLimit(limit);
    final validatedPage = _validatePage(page);
    
    print('📋 [ReportsRepository] Fetching my results - limit: $validatedLimit, page: $validatedPage');
    final uri = _buildUri('/reports/kahoots/my-results', {
      'limit': '$validatedLimit',
      'page': '$validatedPage',
    });
    final json = await _getJson(uri);
    print('📋 [ReportsRepository] My results data received');
    return MyResultsResponse.fromJson(json);
  }

  /// Validates limit parameter
  int _validateLimit(int limit) {
    if (limit < 1) {
      print('⚠️ [ReportsRepository] Invalid limit ($limit), using default: 20');
      return 20;
    }
    if (limit > 100) {
      print('⚠️ [ReportsRepository] Limit exceeds maximum (100), capped at 100');
      return 100;
    }
    return limit;
  }

  /// Validates page paramete
  int _validatePage(int page) {
    if (page < 1) {
      print('⚠️ [ReportsRepository] Invalid page ($page), using default: 1');
      return 1;
    }
    return page;
  }

  @override
  Future<SessionReport> fetchSessionReport(String sessionId) async {
    print('🎮 [ReportsRepository] Fetching session report for sessionId: $sessionId');
    final uri = _buildUri('/reports/sessions/$sessionId');
    final json = await _getJson(uri);
    print('🎮 [ReportsRepository] Session report data received');
    return SessionReport.fromJson(json);
  }

  @override
  Future<PersonalResult> fetchMultiplayerResult(String sessionId) async {
    print('👥 [ReportsRepository] Fetching multiplayer result for sessionId: $sessionId');
    final uri = _buildUri('/reports/multiplayer/$sessionId');
    final json = await _getJson(uri);
    print('👥 [ReportsRepository] Multiplayer result data received');
    return PersonalResult.fromJson(json);
  }

  @override
  Future<PersonalResult> fetchSingleplayerResult(String attemptId) async {
    print('🎯 [ReportsRepository] Fetching singleplayer result for attemptId: $attemptId');
    final uri = _buildUri('/reports/singleplayer/$attemptId');
    final json = await _getJson(uri);
    print('🎯 [ReportsRepository] Singleplayer result data received');
    return PersonalResult.fromJson(json);
  }
}
