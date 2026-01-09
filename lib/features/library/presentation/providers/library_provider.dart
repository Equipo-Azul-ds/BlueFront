import 'package:flutter/foundation.dart';
import 'package:Trivvy/features/library/domain/entities/kahoot_model.dart';
import 'package:Trivvy/features/library/domain/entities/kahoot_progress_model.dart';
import 'package:Trivvy/features/library/application/get_kahoots_use_cases.dart';
import 'package:Trivvy/features/library/application/toggle_favorite_use_case.dart';
import 'package:Trivvy/features/library/application/update_kahoot_progress_usecase.dart';
import 'package:Trivvy/features/library/application/get_kahoot_progress_usecase.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';

enum LibraryState { initial, loading, loaded, error }

class LibraryProvider with ChangeNotifier {
  final GetCreatedKahootsUseCase _getCreated;
  final GetFavoriteKahootsUseCase _getFavorite;
  final GetInProgressKahootsUseCase _getInProgress;
  final GetCompletedKahootsUseCase _getCompleted;
  final ToggleFavoriteUseCase _toggleFavorite;
  final UpdateKahootProgressUseCase _updateProgress;
  final GetKahootProgressUseCase _getKahootProgress;

  final AuthBloc _authBloc;

  String? get userId => _authBloc.currentUser?.id;

  LibraryProvider({
    required GetCreatedKahootsUseCase getCreated,
    required GetFavoriteKahootsUseCase getFavorite,
    required GetInProgressKahootsUseCase getInProgress,
    required GetCompletedKahootsUseCase getCompleted,
    required ToggleFavoriteUseCase toggleFavorite,
    required UpdateKahootProgressUseCase updateProgress,
    required GetKahootProgressUseCase getKahootProgress,
    required AuthBloc authBloc,
  }) : _getCreated = getCreated,
       _getFavorite = getFavorite,
       _getInProgress = getInProgress,
       _getCompleted = getCompleted,
       _toggleFavorite = toggleFavorite,
       _updateProgress = updateProgress,
       _getKahootProgress = getKahootProgress,
       _authBloc = authBloc;

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
    final currentId = userId;
    print('DEBUG BIBLIOTECA: Pidiendo kahoots para el usuario ID: $currentId');

    if (currentId == null) {
      _state = LibraryState.initial;
      notifyListeners();
      return;
    }

    if (_state == LibraryState.loading) return;

    _state = LibraryState.loading;
    notifyListeners();

    try {
      // Si el backend falla por estar vacío, devolvemos una lista vacía por defecto.
      final results = await Future.wait([
        _getCreated(userId: currentId).catchError((e) {
          debugPrint('Info: Lista de creados vacía o error: $e');
          return <Kahoot>[];
        }),
        _getFavorite(userId: currentId).catchError((e) {
          debugPrint('Info: Lista de favoritos vacía o error: $e');
          return <Kahoot>[];
        }),
        _getInProgress(userId: currentId).catchError((e) {
          debugPrint('Info: Lista en progreso vacía o error: $e');
          return <Kahoot>[];
        }),
        _getCompleted(userId: currentId).catchError((e) {
          debugPrint('Info: Lista de completados vacía o error: $e');
          return <Kahoot>[];
        }),
      ]);

      _createdKahoots = results[0];
      _favoriteKahoots = results[1];
      _inProgressKahoots = results[2];
      _completedKahoots = results[3];

      _state = LibraryState.loaded;
    } catch (e) {
      // Este bloque solo se ejecutará si algo falla catastróficamente
      _state = LibraryState.error;
      debugPrint('Error crítico en la biblioteca: $e');
    }
    notifyListeners();
  }

  Future<KahootProgress?> getKahootProgress(String kahootId) {
    final currentId = userId;
    if (currentId == null) return Future.value(null);
    return _getKahootProgress.execute(kahootId: kahootId, userId: currentId);
  }

  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required bool currentStatus,
  }) async {
    final currentId = userId;
    if (currentId == null) return;

    await _toggleFavorite.execute(
      kahootId: kahootId,
      isFavorite: !currentStatus,
      userId: currentId,
    );

    await loadAllLists();
  }

  Future<void> updateKahootProgress({
    required String kahootId,
    required double newPercentage,
    required bool isCompleted,
  }) async {
    final currentId = userId;
    if (currentId == null) return;

    await _updateProgress.execute(
      kahootId: kahootId,
      userId: currentId,
      newPercentage: newPercentage,
      isCompleted: isCompleted,
    );

    await loadAllLists();
  }
}
