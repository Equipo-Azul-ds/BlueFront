import 'package:flutter/foundation.dart';

import '../../application/use_cases/report_usecases.dart';
import '../../domain/entities/report_model.dart';

/// BLoC para cargar el detalle de un reporte (personal o de sesión).
class ReportDetailBloc extends ChangeNotifier {
  ReportDetailBloc({
    required this.getSessionReportUseCase,
    required this.getMultiplayerResultUseCase,
    required this.getSingleplayerResultUseCase,
  });

  final GetSessionReportUseCase getSessionReportUseCase;
  final GetMultiplayerResultUseCase getMultiplayerResultUseCase;
  final GetSingleplayerResultUseCase getSingleplayerResultUseCase;

  bool isLoading = false;
  String? error;
  SessionReport? sessionReport;
  PersonalResult? personalResult;

  Future<void> loadFromSummary(ReportSummary summary) {
    return loadPersonalResult(summary.gameType, summary.gameId);
  }

  Future<void> loadPersonalResult(GameType type, String gameId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = type == GameType.singleplayer
          ? await getSingleplayerResultUseCase(gameId)
          : await getMultiplayerResultUseCase(gameId);
      personalResult = result;
    } catch (e) {
      error = e.toString();
      personalResult = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReport(GameType type, String gameId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      switch (type) {
        case GameType.singleplayer:
          personalResult = await getSingleplayerResultUseCase(gameId);
          sessionReport = null;
          break;
        case GameType.multiplayer_player:
          personalResult = await getMultiplayerResultUseCase(gameId);
          sessionReport = null;
          break;
        case GameType.multiplayer_host:
          sessionReport = await getSessionReportUseCase(gameId);
          personalResult = null;
          break;
      }
    } catch (e) {
      error = e.toString();
      personalResult = null;
      sessionReport = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionReport(String sessionId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      sessionReport = await getSessionReportUseCase(sessionId);
    } catch (e) {
      error = e.toString();
      sessionReport = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
