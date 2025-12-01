import '../../domain/entities/kahoot_model.dart';
import '../../domain/entities/kahoot_progress_model.dart';
import '../../domain/repositories/library_repository.dart';

// Implementación de simulación que devuelve datos fijos para el desarrollo
class MockLibraryRepository implements LibraryRepository {
  // Datos simulados (MOCKS)
  final List<Kahoot> _mockKahoots = [
    Kahoot(
      id: 'k1',
      title: 'Principios de Arquitectura Limpia',
      description: 'Conceptos SOLID y DDD.',
      authorId: 'user_123', // Creado por el usuario
      createdAt: DateTime(2025, 1, 1),
      visibility: 'Public',
      status: 'Published',
    ),
    Kahoot(
      id: 'k2',
      title: 'Física Cuántica Básica',
      description: 'Primeros pasos en el mundo subatómico.',
      authorId: 'user_123', // Creado por el usuario
      createdAt: DateTime(2025, 10, 20),
      visibility: 'Public',
      status: 'Draft', // Borrador (H7.1)
    ),
    Kahoot(
      id: 'k3',
      title: 'Historia de la Antigua Roma',
      description: 'Desde la República hasta el Imperio.',
      authorId: 'user_999',
      createdAt: DateTime(2025, 9, 15),
      visibility: 'Public',
      status: 'Published',
    ),
  ];

  final List<KahootProgress> _mockProgress = [
    // Usuario tiene el k1 como favorito y lo completó
    KahootProgress(
      kahootId: 'k1',
      userId: 'user_123',
      isFavorite: true, // Favorito (H7.2)
      progressPercentage: 100,
      lastAttemptAt: DateTime(2025, 1, 10),
      isCompleted: true, // Completado (H7.4)
    ),
    // Usuario tiene el k3 en progreso
    KahootProgress(
      kahootId: 'k3',
      userId: 'user_123',
      isFavorite: false,
      progressPercentage: 50, // En Progreso (H7.3)
      lastAttemptAt: DateTime(2025, 11, 20),
      isCompleted: false,
    ),
  ];

  // =======================================================
  // Implementación de los métodos de la interfaz
  // =======================================================

  // H7.1: Creados y Borradores
  @override
  Future<List<Kahoot>> getCreatedKahoots({required String userId}) async {
    // Simula el filtro: quices creados por el usuario
    return Future.value(
      _mockKahoots.where((k) => k.authorId == userId).toList(),
    );
  }

  // H7.2: Favoritos
  @override
  Future<List<Kahoot>> getFavoriteKahoots({required String userId}) async {
    final favoriteProgress = _mockProgress
        .where((p) => p.userId == userId && p.isFavorite)
        .toList();

    // Mapea los IDs de progreso a los objetos Kahoot
    final favoriteKahoots = _mockKahoots
        .where((k) => favoriteProgress.any((p) => p.kahootId == k.id))
        .toList();

    return Future.value(favoriteKahoots);
  }

  // H7.3: En Progreso
  @override
  Future<List<Kahoot>> getInProgressKahoots({required String userId}) async {
    final inProgress = _mockProgress
        .where(
          (p) =>
              p.userId == userId && p.progressPercentage > 0 && !p.isCompleted,
        )
        .toList();

    final inProgressKahoots = _mockKahoots
        .where((k) => inProgress.any((p) => p.kahootId == k.id))
        .toList();

    return Future.value(inProgressKahoots);
  }

  // H7.4: Completados
  @override
  Future<List<Kahoot>> getCompletedKahoots({required String userId}) async {
    final completed = _mockProgress
        .where((p) => p.userId == userId && p.isCompleted)
        .toList();

    final completedKahoots = _mockKahoots
        .where((k) => completed.any((p) => p.kahootId == k.id))
        .toList();

    return Future.value(completedKahoots);
  }

  // Utilidad
  @override
  Future<KahootProgress?> getProgressForKahoot({
    required String kahootId,
    required String userId,
  }) async {
    try {
      final progress = _mockProgress.firstWhere(
        (p) => p.kahootId == kahootId && p.userId == userId,
      );
      return Future.value(progress);
    } catch (e) {
      return Future.value(null);
    }
  }

  @override
  Future<Kahoot> getKahootById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final kahoot = _mockKahoots.firstWhere(
      (k) => k.id == id,
      orElse: () => throw Exception('Kahoot no encontrado con ID: $id'),
    );
    return kahoot;
  }
}
