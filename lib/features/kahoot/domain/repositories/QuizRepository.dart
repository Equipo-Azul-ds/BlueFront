import '../entities/Quiz.dart';

abstract class QuizRepository {
  Future<Quiz> save(Quiz quiz);                // devuelve el quiz guardado
  Future<Quiz?> find(String id);               // null si no existe
  Future<void> delete(String id);
  Future<List<Quiz>> searchByAuthor(String authorId);
}