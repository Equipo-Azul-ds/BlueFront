import 'package:flutter/foundation.dart';

import '../../application/use_cases/report_usecases.dart';
import '../../domain/entities/report_model.dart';

/// BLoC dedicado para cargar informes de sesiones que el usuario ha alojado como host.
/// Este BLoC solo maneja reportes de sesión (endpoint /reports/sessions/:sessionId).
class HostSessionReportBloc extends ChangeNotifier {
  HostSessionReportBloc({required this.getSessionReportUseCase});

  final GetSessionReportUseCase getSessionReportUseCase;

  bool isLoading = false;
  String? error;
  SessionReport? sessionReport;

  /// Carga un informe de sesión dado el sessionId.
  Future<void> loadSessionReport(String sessionId) async {
    isLoading = true;
    error = null;
    sessionReport = null;
    notifyListeners();

    try {
      sessionReport = await getSessionReportUseCase(sessionId);
      error = null;
    } catch (e) {
      error = e.toString();
      sessionReport = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresca el informe actual.
  Future<void> refresh() async {
    if (sessionReport != null) {
      await loadSessionReport(sessionReport!.sessionId);
    }
  }
}
