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
      description:
          'Conceptos SOLID y DDD. Este Kahoot explica los principios fundamentales del diseño de software limpio.',
      authorId: 'user_123',
      createdAt: DateTime(2025, 1, 1),
      visibility: 'Public',
      status: 'Published',
    ),
    Kahoot(
      id: 'k2',
      title: 'Física Cuántica Básica',
      description: 'Primeros pasos en el mundo subatómico.',
      authorId: 'user_123',
      createdAt: DateTime(2025, 10, 20),
      visibility: 'Public',
      status: 'Draft',
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

  // Lista mutable para actualizar el estado de favoritos y progreso
  List<KahootProgress> _mockProgress = [
    // Kahoot k1: Completado y Favorito
    KahootProgress(
      kahootId: 'k1',
      userId: 'user_123',
      isFavorite: true,
      progressPercentage: 100,
      lastAttemptAt: DateTime(2025, 1, 10), // Requerido
      isCompleted: true,
    ),
    // Kahoot k3: En progreso
    KahootProgress(
      kahootId: 'k3',
      userId: 'user_123',
      isFavorite: false,
      progressPercentage: 50,
      lastAttemptAt: DateTime(2025, 11, 20), // Requerido
      isCompleted: false,
    ),
  ];

  // =======================================================
  // Implementación de los métodos de la interfaz
  // =======================================================

  @override
  Future<List<Kahoot>> getCreatedKahoots({required String userId}) {
    return Future.value(
      _mockKahoots.where((k) => k.authorId == userId).toList(),
    );
  }

  @override
  Future<List<Kahoot>> getFavoriteKahoots({required String userId}) {
    final favoriteProgress = _mockProgress
        .where((p) => p.userId == userId && p.isFavorite)
        .toList();
    final favoriteKahoots = _mockKahoots
        .where((k) => favoriteProgress.any((p) => p.kahootId == k.id))
        .toList();
    return Future.value(favoriteKahoots);
  }

  @override
  Future<List<Kahoot>> getInProgressKahoots({required String userId}) {
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

  @override
  Future<List<Kahoot>> getCompletedKahoots({required String userId}) {
    final completed = _mockProgress
        .where((p) => p.userId == userId && p.isCompleted)
        .toList();
    final completedKahoots = _mockKahoots
        .where((k) => completed.any((p) => p.kahootId == k.id))
        .toList();
    return Future.value(completedKahoots);
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

  // =======================================================
  // Implementación de la Mutación (TOGGLE FAVORITE)
  // =======================================================
  @override
  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required String userId,
    required bool isFavorite,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockProgress.indexWhere(
      (p) => p.kahootId == kahootId && p.userId == userId,
    );

    if (index != -1) {
      // 1. Si ya existe un progreso, lo actualizamos (creando una nueva instancia).
      final oldProgress = _mockProgress[index];

      _mockProgress[index] = KahootProgress(
        kahootId: oldProgress.kahootId,
        userId: oldProgress.userId,
        isFavorite: isFavorite, // <-- El valor que queremos cambiar
        progressPercentage: oldProgress.progressPercentage,
        lastAttemptAt:
            oldProgress.lastAttemptAt, // Mantenemos el valor original
        isCompleted: oldProgress.isCompleted,
      );
    } else {
      // 2. Si no existe, creamos un nuevo registro.
      _mockProgress.add(
        KahootProgress(
          kahootId: kahootId,
          userId: userId,
          isFavorite: isFavorite,
          progressPercentage: 0,
          lastAttemptAt: DateTime.now(), // <-- Valor requerido en la creación
          isCompleted: false,
        ),
      );
    }
  }

  @override
  Future<void> updateProgress({
    required String kahootId,
    required String userId,
    required double newPercentage,
    required bool isCompleted,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockProgress.indexWhere(
      (p) => p.kahootId == kahootId && p.userId == userId,
    );

    if (index != -1) {
      // 1. Si ya existe un progreso, lo actualizamos y reemplazamos.
      final oldProgress = _mockProgress[index];

      // Creamos una nueva instancia de progreso con los nuevos valores
      _mockProgress[index] = KahootProgress(
        kahootId: oldProgress.kahootId,
        userId: oldProgress.userId,
        isFavorite: oldProgress.isFavorite,
        progressPercentage: newPercentage.toInt(),
        lastAttemptAt: DateTime.now(),
        isCompleted: isCompleted,
      );
    } else {
      // 2. Si no existe, creamos un nuevo registro.
      _mockProgress.add(
        KahootProgress(
          kahootId: kahootId,
          userId: userId,
          isFavorite: false, // Por defecto, al empezar un Kahoot no es favorito
          progressPercentage: newPercentage.toInt(),
          lastAttemptAt: DateTime.now(),
          isCompleted: isCompleted,
        ),
      );
    }
  }
}
