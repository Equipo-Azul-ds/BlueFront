import 'package:flutter/foundation.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../domain/entities/kahoot_progress_model.dart';
import '../../application/get_kahoots_use_cases.dart';
import '../../application/toggle_favorite_use_case.dart';
import '../../application/update_kahoot_progress_usecase.dart';
import '../../application/get_kahoot_progress_usecase.dart';

// Definición de los estados para la interfaz de usuario
enum LibraryState { initial, loading, loaded, error }

class LibraryProvider with ChangeNotifier {
  final GetCreatedKahootsUseCase _getCreated;
  final GetFavoriteKahootsUseCase _getFavorite;
  final GetInProgressKahootsUseCase _getInProgress;
  final GetCompletedKahootsUseCase _getCompleted;
  final ToggleFavoriteUseCase _toggleFavorite;
  final UpdateKahootProgressUseCase _updateProgress;
  final GetKahootProgressUseCase _getKahootProgress;

  LibraryProvider({
    required GetCreatedKahootsUseCase getCreated,
    required GetFavoriteKahootsUseCase getFavorite,
    required GetInProgressKahootsUseCase getInProgress,
    required GetCompletedKahootsUseCase getCompleted,
    required ToggleFavoriteUseCase toggleFavorite,
    required UpdateKahootProgressUseCase updateProgress,
    required GetKahootProgressUseCase getKahootProgress,
  }) : _getCreated = getCreated,
       _getFavorite = getFavorite,
       _getInProgress = getInProgress,
       _getCompleted = getCompleted,
       _toggleFavorite = toggleFavorite,
       _updateProgress = updateProgress,
       _getKahootProgress = getKahootProgress;

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
    if (_state == LibraryState.loading) return;

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
      debugPrint('Error al cargar listas de la biblioteca: $e');
    }
    notifyListeners();
  }

  Future<KahootProgress?> getKahootProgress(String kahootId, String userId) {
    return _getKahootProgress.execute(kahootId: kahootId, userId: userId);
  }

  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required bool currentStatus,
    required String userId,
  }) async {
    await _toggleFavorite.execute(
      kahootId: kahootId,
      isFavorite: !currentStatus,
    );

    await loadAllLists(userId);
  }

  Future<void> updateKahootProgress({
    required String kahootId,
    required String userId,
    required double newPercentage,
    required bool isCompleted,
  }) async {
    await _updateProgress.execute(
      kahootId: kahootId,
      userId: userId,
      newPercentage: newPercentage,
      isCompleted: isCompleted,
    );

    // Recargar todas las listas para reflejar el cambio en la UI
    await loadAllLists(userId);
  }
}
