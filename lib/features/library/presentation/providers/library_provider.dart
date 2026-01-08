import 'package:flutter/foundation.dart';
import 'package:Trivvy/features/library/domain/entities/kahoot_model.dart';
import 'package:Trivvy/features/library/domain/entities/kahoot_progress_model.dart';
import 'package:Trivvy/features/library/application/get_kahoots_use_cases.dart';
import 'package:Trivvy/features/library/application/toggle_favorite_use_case.dart';
import 'package:Trivvy/features/library/application/update_kahoot_progress_usecase.dart';
import 'package:Trivvy/features/library/application/get_kahoot_progress_usecase.dart';

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

  final String _testUserId = 'massielprueba';
  String get userId => _testUserId;
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

  Future<void> loadAllLists() async {
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
      _createdKahoots = [];
      _favoriteKahoots = [];
      _state = LibraryState.error;
      debugPrint('Error al cargar listas de la biblioteca: $e');
    }
    notifyListeners();
  }

  Future<KahootProgress?> getKahootProgress(String kahootId) {
    return _getKahootProgress.execute(kahootId: kahootId, userId: userId);
  }

  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required bool currentStatus,
  }) async {
    await _toggleFavorite.execute(
      kahootId: kahootId,
      isFavorite: !currentStatus,
      userId: userId,
    );

    await loadAllLists();
  }

  Future<void> updateKahootProgress({
    required String kahootId,
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
    await loadAllLists();
  }
}
