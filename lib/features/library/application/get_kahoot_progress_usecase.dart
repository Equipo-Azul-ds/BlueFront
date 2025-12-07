import '../domain/entities/kahoot_progress_model.dart';
import '../domain/repositories/library_repository.dart';

class GetKahootProgressUseCase {
  final LibraryRepository repository;

  GetKahootProgressUseCase({required this.repository});

  Future<KahootProgress?> execute({
    required String kahootId,
    required String userId,
  }) async {
    return repository.getProgressForKahoot(kahootId: kahootId, userId: userId);
  }
}
