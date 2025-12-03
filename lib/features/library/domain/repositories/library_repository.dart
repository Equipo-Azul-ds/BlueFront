import '../entities/kahoot_model.dart';
import '../entities/kahoot_progress_model.dart';

// El repositorio usa el tipo Future<List<T>> para operaciones asíncronas de lectura.
abstract class LibraryRepository {
  // H7.1: Quices creados (por el usuario actual) y borradores
  Future<List<Kahoot>> getCreatedKahoots({required String userId});

  // H7.2: Quices marcados como favoritos (usando el modelo KahootProgress)
  Future<List<Kahoot>> getFavoriteKahoots({required String userId});

  // H7.3: Quices en progreso (usando el modelo KahootProgress)
  Future<List<Kahoot>> getInProgressKahoots({required String userId});

  // H7.4: Quices completados (usando el modelo KahootProgress)
  Future<List<Kahoot>> getCompletedKahoots({required String userId});

  // Obtener el progreso de un Kahoot específico
  Future<KahootProgress?> getProgressForKahoot({
    required String kahootId,
    required String userId,
  });

  // Obtener un Kahoot por su ID
  Future<Kahoot> getKahootById(String id);

  // Método para cambiar el estado de favorito
  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required String userId,
    required bool isFavorite,
  });
}
