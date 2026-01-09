import '../../domain/entities/report_model.dart';
import '../../domain/repositories/reports_repository.dart';
import '../dtos/report_dtos.dart';

/// Use cases para consumir los reportes desde UI.
class GetMyResultsUseCase {
  GetMyResultsUseCase(this._repository);
  final ReportsRepository _repository;

  Future<MyResultsResponse> call(MyResultsQueryDto query) {
    return _repository.fetchMyResults(limit: query.limit, page: query.page);
  }
}

class GetSessionReportUseCase {
  GetSessionReportUseCase(this._repository);
  final ReportsRepository _repository;

  Future<SessionReport> call(String sessionId) {
    return _repository.fetchSessionReport(sessionId);
  }
}

class GetMultiplayerResultUseCase {
  GetMultiplayerResultUseCase(this._repository);
  final ReportsRepository _repository;

  Future<PersonalResult> call(String sessionId) {
    return _repository.fetchMultiplayerResult(sessionId);
  }
}

class GetSingleplayerResultUseCase {
  GetSingleplayerResultUseCase(this._repository);
  final ReportsRepository _repository;

  Future<PersonalResult> call(String attemptId) {
    return _repository.fetchSingleplayerResult(attemptId);
  }
}
