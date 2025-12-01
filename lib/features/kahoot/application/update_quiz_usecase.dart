import '../application/dtos/create_quiz_dto.dart';
import '../domain/repositories/QuizRepository.dart';
import '../domain/entities/Quiz.dart';
import '../domain/entities/Question.dart' as Q;
import '../domain/entities/Answer.dart' as A;
import 'package:uuid/uuid.dart';

class UpdateKahootUseCase {
  final QuizRepository repository;
  UpdateKahootUseCase(this.repository);

  /// Actualiza un quiz existente. `quizId` es el id del quiz a actualizar.
  /// `dto` contiene la nueva metadata y preguntas (igual shape que creación).
  Future<Quiz> run(String quizId, CreateQuizDto dto) async {
    // 1) Obtener el quiz existente (opcional: para validar existencia)
    final existing = await repository.find(quizId);
    if (existing == null) {
      throw Exception('Quiz not found');
    }
    // Build an updated Quiz entity by merging existing values with provided DTO.
    // This avoids constructing via JSON where missing/null fields could break non-nullable constructors.

    final titleTrim = dto.title.trim();
    if (titleTrim.isEmpty || titleTrim.length > 95) {
      throw Exception('El título del quiz debe tener entre 1 y 95 caracteres.');
    }

    // Map questions from DTO if provided, otherwise preserve existing questions.
    final uid = Uuid();
    final questions = (dto.questions.isNotEmpty)
        ? dto.questions.map((qDto) {
            final qid = 'q_${uid.v4()}';
            final q = Q.Question(
              questionId: qid,
              quizId: quizId,
              text: qDto.questionText,
              mediaUrl: qDto.mediaUrl,
              type: qDto.questionType,
              timeLimit: qDto.timeLimit,
              points: qDto.points ?? 0,
              answers: qDto.answers.map((aDto) {
                return A.Answer(
                  answerId: 'a_${uid.v4()}',
                  questionId: qid,
                  isCorrect: aDto.isCorrect,
                  text: aDto.answerText,
                  mediaUrl: aDto.answerImage,
                );
              }).toList(),
            );
            return q;
          }).toList()
        : existing.questions;

    final updatedEntity = Quiz(
      quizId: quizId,
      authorId: dto.authorId.isNotEmpty ? dto.authorId : existing.authorId,
      title: titleTrim,
      description: dto.description ?? existing.description,
      visibility: dto.visibility.isNotEmpty ? dto.visibility : existing.visibility,
      status: dto.status ?? existing.status,
      category: dto.category ?? existing.category,
      themeId: dto.themeId ?? existing.themeId,
      templateId: existing.templateId,
      coverImageUrl: dto.coverImage ?? existing.coverImageUrl,
      isLocal: false,
      createdAt: existing.createdAt,
      questions: questions,
    );

    // Persist updated entity
    final saved = await repository.save(updatedEntity);
    return saved;
  }
}