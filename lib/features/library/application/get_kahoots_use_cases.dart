import '../domain/entities/kahoot_model.dart';
import '../domain/repositories/library_repository.dart';

// Este Caso de Uso maneja la historia H7.1: Quices Creados y Borradores
class GetCreatedKahootsUseCase {
  final LibraryRepository repository;

  const GetCreatedKahootsUseCase({required this.repository});

  Future<List<Kahoot>> call({required String userId}) {
    // La lógica de negocio: solo llamar al repositorio.
    return repository.getCreatedKahoots(userId: userId);
  }
}

// Este Caso de Uso maneja la historia H7.2: Quices Favoritos
class GetFavoriteKahootsUseCase {
  final LibraryRepository repository;

  const GetFavoriteKahootsUseCase({required this.repository});

  Future<List<Kahoot>> call({required String userId}) {
    return repository.getFavoriteKahoots(userId: userId);
  }
}

// Este Caso de Uso maneja la historia H7.3: Quices En Progreso
class GetInProgressKahootsUseCase {
  final LibraryRepository repository;

  const GetInProgressKahootsUseCase({required this.repository});

  Future<List<Kahoot>> call({required String userId}) {
    return repository.getInProgressKahoots(userId: userId);
  }
}

// Este Caso de Uso maneja la historia H7.4: Quices Completados
class GetCompletedKahootsUseCase {
  final LibraryRepository repository;

  const GetCompletedKahootsUseCase({required this.repository});

  Future<List<Kahoot>> call({required String userId}) {
    return repository.getCompletedKahoots(userId: userId);
  }
}
