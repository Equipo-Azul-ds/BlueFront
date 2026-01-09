abstract class QuizReadService {
  /// Verifica que el quiz pertenezca al usuario.
  Future<bool> quizBelongsToUser({required String quizId, required String userId});
}
