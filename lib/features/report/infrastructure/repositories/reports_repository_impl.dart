import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/report_model.dart';
import '../../domain/repositories/reports_repository.dart';

/// Provides HTTP headers (Authorization, etc.) at call time.
typedef HeadersProvider = Future<Map<String, String>> Function();

/// Implementación con soporte para auth headers.
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({
    required this.baseUrl,
    required this.headersProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final HeadersProvider headersProvider;

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final headers = await headersProvider();
    final resp = await _client.get(uri, headers: headers);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw Exception('Error al consultar ${uri.path}: ${resp.statusCode}');
  }

  @override
  Future<MyResultsResponse> fetchMyResults({int limit = 20, int page = 1}) async {
    final uri = _buildUri('/reports/kahoots/my-results', {
      'limit': '$limit',
      'page': '$page',
    });
    final json = await _getJson(uri);
    return MyResultsResponse.fromJson(json);
  }

  @override
  Future<SessionReport> fetchSessionReport(String sessionId) async {
    final uri = _buildUri('/reports/sessions/$sessionId');
    final json = await _getJson(uri);
    return SessionReport.fromJson(json);
  }

  @override
  Future<PersonalResult> fetchMultiplayerResult(String sessionId) async {
    final uri = _buildUri('/reports/multiplayer/$sessionId');
    final json = await _getJson(uri);
    return PersonalResult.fromJson(json);
  }

  @override
  Future<PersonalResult> fetchSingleplayerResult(String attemptId) async {
    final uri = _buildUri('/reports/singleplayer/$attemptId');
    final json = await _getJson(uri);
    return PersonalResult.fromJson(json);
  }
}
