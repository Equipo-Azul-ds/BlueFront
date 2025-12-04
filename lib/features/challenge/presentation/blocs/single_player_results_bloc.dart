import 'package:flutter/foundation.dart';
import '../../domain/entities/single_player_game.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../../application/use_cases/single_player_usecases.dart';

// BLoC usado en la pantalla de resultados. Encapsula la lógica para
// cargar el resumen final de un intento y notificar a la UI de cambios.
class SinglePlayerResultsBloc extends ChangeNotifier {
  final SinglePlayerGameRepository repository;
  final GetSummaryUseCase getSummaryUseCase;

  bool isLoading = false;
  String? error;
  SinglePlayerGame? summaryGame;

  SinglePlayerResultsBloc({
    required this.repository,
    required this.getSummaryUseCase,
  });

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Carga el resumen del intento (`gameId`) usando el caso de uso.
  // Maneja estados de carga y errores para que la UI los muestre.
  Future<void> load(String gameId) async {
    _setLoading(true);
    error = null;
    notifyListeners();

    try {
      final res = await getSummaryUseCase.execute(gameId);
      summaryGame = res.summaryGame;
    } catch (e) {
      error = e.toString();
      summaryGame = null;
    } finally {
      _setLoading(false);
    }
  }

  // Reintenta cargar el resumen (alias para `load`).
  Future<void> retry(String gameId) => load(gameId);
}
