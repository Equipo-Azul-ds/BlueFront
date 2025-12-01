import 'package:flutter/foundation.dart';
import '../../domain/entities/SinglePlayerGame.dart';
import '../../domain/repositories/SinglePlayerGameRepository.dart';

class SinglePlayerResultsBloc extends ChangeNotifier {
  final SinglePlayerGameRepository repository;

  SinglePlayerResultsBloc({required this.repository});

  bool loading = false;
  String? error;
  SinglePlayerGame? game;

  Future<void> load(String gameId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final g = await repository.getGame(gameId);
      if (g == null) {
        error = 'Game not found';
        game = null;
      } else {
        game = g;
      }
    } catch (e) {
      error = e.toString();
      game = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> retry(String gameId) => load(gameId);
}
