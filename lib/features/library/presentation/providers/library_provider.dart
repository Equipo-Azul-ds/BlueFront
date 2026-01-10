import 'package:flutter/foundation.dart';
import 'package:Trivvy/features/library/domain/entities/kahoot_model.dart';
import 'package:Trivvy/features/library/application/get_kahoots_use_cases.dart';
import 'package:Trivvy/features/library/application/toggle_favorite_use_case.dart';

enum LibraryState { initial, loading, loaded, error }

class LibraryProvider with ChangeNotifier {
  final GetCreatedKahootsUseCase _getCreated;
  final GetFavoriteKahootsUseCase _getFavorite;
  final GetInProgressKahootsUseCase _getInProgress;
  final GetCompletedKahootsUseCase _getCompleted;
  final ToggleFavoriteUseCase _toggleFavorite;

  LibraryProvider({
    required GetCreatedKahootsUseCase getCreated,
    required GetFavoriteKahootsUseCase getFavorite,
    required GetInProgressKahootsUseCase getInProgress,
    required GetCompletedKahootsUseCase getCompleted,
    required ToggleFavoriteUseCase toggleFavorite,
  }) : _getCreated = getCreated,
       _getFavorite = getFavorite,
       _getInProgress = getInProgress,
       _getCompleted = getCompleted,
       _toggleFavorite = toggleFavorite;

  LibraryState _state = LibraryState.initial;
  LibraryState get state => _state;

  List<Kahoot> _createdKahoots = [];
  List<Kahoot> get createdKahoots => _createdKahoots;

  List<Kahoot> _favoriteKahoots = [];
  List<Kahoot> get favoriteKahoots => _favoriteKahoots;

  List<Kahoot> _inProgressKahoots = [];
  List<Kahoot> get inProgressKahoots => _inProgressKahoots;

  List<Kahoot> _completedKahoots = [];
  List<Kahoot> get completedKahoots => _completedKahoots;

  Future<void> loadAllLists(String userId) async {
    _state = LibraryState.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getCreated(userId: userId),
        _getFavorite(userId: userId),
        _getInProgress(userId: userId),
        _getCompleted(userId: userId),
      ]);

      _createdKahoots = results[0];
      _favoriteKahoots = results[1];
      _inProgressKahoots = results[2];
      _completedKahoots = results[3];

      _state = LibraryState.loaded;
    } catch (e) {
      _state = LibraryState.error;
      debugPrint('Error en Biblioteca: $e');
    }
    notifyListeners();
  }

  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required bool currentStatus,
    required String userId,
  }) async {
    try {
      await _toggleFavorite.execute(
        kahootId: kahootId,
        userId: userId,
        isFavorite: currentStatus,
      );

      if (currentStatus) {
        // Si era favorito, lo quitamos localmente
        _favoriteKahoots.removeWhere((k) => k.id == kahootId);
      } else {
        // Si no era favorito, recargamos solo la lista de favoritos
        // para obtener el objeto Kahoot completo desde el servidor.
        _favoriteKahoots = await _getFavorite(userId: userId);
      }

      notifyListeners(); // Refresca la UI al instante
    } catch (e) {
      debugPrint('Error toggleFavorite en Provider: $e');
      await loadAllLists(userId);
    }
  }
}
