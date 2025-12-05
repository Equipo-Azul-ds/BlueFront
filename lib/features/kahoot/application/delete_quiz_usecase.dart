import '../domain/repositories/QuizRepository.dart';

class DeleteKahootUseCase {
  final QuizRepository repository;
  DeleteKahootUseCase(this.repository);

  Future<void> run(String quizId) async {
    await repository.delete(quizId);
  }
}