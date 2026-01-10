import '../entities/kahoot_model.dart';

abstract class LibraryRepository {
  Future<List<Kahoot>> getCreatedKahoots({required String userId});
  Future<List<Kahoot>> getFavoriteKahoots({required String userId});
  Future<List<Kahoot>> getInProgressKahoots({required String userId});
  Future<List<Kahoot>> getCompletedKahoots({required String userId});

  Future<Kahoot> getKahootById(String id, {String? userId});

  Future<void> toggleFavoriteStatus({
    required String kahootId,
    required String userId,
    required bool isFavorite,
  });
}
