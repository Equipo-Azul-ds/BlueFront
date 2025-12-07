import '../domain/repositories/library_repository.dart';

class UpdateKahootProgressUseCase {
  final LibraryRepository repository;

  UpdateKahootProgressUseCase({required this.repository});

  Future<void> execute({
    required String kahootId,
    required String userId,
    required double newPercentage,
    required bool isCompleted,
  }) async {
    await repository.updateProgress(
      kahootId: kahootId,
      userId: userId,
      newPercentage: newPercentage,
      isCompleted: isCompleted,
    );
  }
}
