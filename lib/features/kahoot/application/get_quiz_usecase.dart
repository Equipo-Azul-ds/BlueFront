import '../domain/entities/Quiz.dart';
import '../domain/repositories/QuizRepository.dart';

class GetKahootUseCase {
  final QuizRepository repository;
  GetKahootUseCase(this.repository);

  Future<Quiz> run(String quizId) async {
    final quiz = await repository.find(quizId);
    if (quiz == null) {
      throw Exception('Quiz not found'); // BLoC/Controller lo mapea a 404
    }
    return quiz;
  }
}