import 'package:flutter/foundation.dart';
import '../../domain/entities/single_player_game.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../../application/use_cases/single_player_usecases.dart';

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

  Future<void> retry(String gameId) => load(gameId);
}
