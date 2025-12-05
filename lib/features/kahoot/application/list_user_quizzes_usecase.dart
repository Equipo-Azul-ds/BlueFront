import '../domain/entities/Quiz.dart';
import '../domain/repositories/QuizRepository.dart';

class ListUserKahootsUseCase {
  final QuizRepository repository;
  ListUserKahootsUseCase(this.repository);

  Future<List<Quiz>> run(String authorId) async {
    return await repository.searchByAuthor(authorId);
  }
}