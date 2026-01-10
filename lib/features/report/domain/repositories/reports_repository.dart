import '../entities/report_model.dart';

/// Contrato para obtener reportes desde la API.
abstract class ReportsRepository {
  Future<MyResultsResponse> fetchMyResults({int limit = 20, int page = 1});

  Future<SessionReport> fetchSessionReport(String sessionId);

  Future<PersonalResult> fetchMultiplayerResult(String sessionId);

  Future<PersonalResult> fetchSingleplayerResult(String attemptId);
}
