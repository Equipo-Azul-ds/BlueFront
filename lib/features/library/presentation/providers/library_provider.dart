import 'package:flutter/foundation.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../application/get_kahoots_use_cases.dart';

// Definición de los estados para la interfaz de usuario
enum LibraryState { initial, loading, loaded, error }

class LibraryProvider with ChangeNotifier {
  // Los Casos de Uso son inyectados
  final GetCreatedKahootsUseCase _getCreated;
  final GetFavoriteKahootsUseCase _getFavorite;
  final GetInProgressKahootsUseCase _getInProgress;
  final GetCompletedKahootsUseCase _getCompleted;

  // El constructor REQUIERE que se inyecten todas las dependencias
  LibraryProvider({
    required GetCreatedKahootsUseCase getCreated,
    required GetFavoriteKahootsUseCase getFavorite,
    required GetInProgressKahootsUseCase getInProgress,
    required GetCompletedKahootsUseCase getCompleted,
  }) : _getCreated = getCreated,
       _getFavorite = getFavorite,
       _getInProgress = getInProgress,
       _getCompleted = getCompleted;

  // Variables de Estado
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

  // Lógica principal: Cargar todas las listas al mismo tiempo
  Future<void> loadAllLists(String userId) async {
    if (_state == LibraryState.loading) return;

    _state = LibraryState.loading;
    notifyListeners();

    try {
      // Usamos Future.wait para cargar las cuatro listas en paralelo
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
}
