import '../domain/repositories/library_repository.dart';

class ToggleFavoriteUseCase {
  final LibraryRepository repository;

  ToggleFavoriteUseCase({required this.repository});

  Future<void> execute({
    required String kahootId,
    required bool isFavorite,
    required String userId,
  }) {
    return repository.toggleFavoriteStatus(
      kahootId: kahootId,
      userId: userId,
      isFavorite: isFavorite,
    );
  }
}
