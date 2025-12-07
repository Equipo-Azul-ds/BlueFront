import '../domain/entities/kahoot_model.dart';
import '../domain/repositories/library_repository.dart';

class GetKahootDetailUseCase {
  final LibraryRepository repository;

  GetKahootDetailUseCase({required this.repository});

  Future<Kahoot> execute(String kahootId) {
    return repository.getKahootById(kahootId);
  }
}
