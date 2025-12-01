import '../application/dtos/create_quiz_dto.dart';
import '../domain/repositories/QuizRepository.dart';
import '../domain/entities/Quiz.dart';
import '../domain/entities/Question.dart' as Q;
import '../domain/entities/Answer.dart' as A;
import 'package:uuid/uuid.dart';

class CreateQuizUsecase {
  final QuizRepository repository;

  CreateQuizUsecase(this.repository);

  //La idea de esto es que al momento de crear el quiz, mapea el DTO a entidad, 
  //y persiste en el repo. Retorna la entidad quiz que es retornada por el repo/back

  Future<Quiz> run(CreateQuizDto dto) async {
    // Build a Quiz entity explicitly for creation.
    // Use an empty `quizId` so that repository.save() treats it as new and POSTs.
    final uid = Uuid();

    final questions = dto.questions.map((qDto) {
      final qid = 'q_${uid.v4()}';
      final answers = qDto.answers.map((aDto) {
        final aid = 'a_${uid.v4()}';
        // Map DTO fields (prefer text over image id/path)
        final text = aDto.answerText;
        final media = aDto.answerImage;
        return A.Answer(
          answerId: aid,
          questionId: qid,
          isCorrect: aDto.isCorrect,
          text: text,
          mediaUrl: media,
        );
      }).toList();

      return Q.Question(
        questionId: qid,
        quizId: '',
        text: qDto.questionText,
        mediaUrl: qDto.mediaUrl,
        type: qDto.questionType,
        timeLimit: qDto.timeLimit,
        points: qDto.points ?? 0,
        answers: answers,
      );
    }).toList();

    final titleTrim = dto.title.trim();
    if (titleTrim.isEmpty || titleTrim.length > 95) {
      throw Exception('El título del quiz debe tener entre 1 y 95 caracteres.');
    }

    final quizEntity = Quiz(
      quizId: '',
      authorId: dto.authorId,
      title: titleTrim,
      description: dto.description ?? '',
      visibility: dto.visibility,
      status: dto.status ?? 'draft',
      category: dto.category ?? 'Tecnología',
      themeId: dto.themeId ?? '',
      coverImageUrl: dto.coverImage,
      isLocal: false,
      createdAt: DateTime.now(),
      questions: questions,
    );

    // Persist via repository (will choose POST because quizId is empty)
    try {
      print('[CreateQuizUsecase] Creating quiz -> title="${quizEntity.title}", author=${quizEntity.authorId}, questions=${quizEntity.questions.length}');
      final created = await repository.save(quizEntity);
      print('[CreateQuizUsecase] Repository returned created -> id=${created.quizId}, title="${created.title}"');

      // Verify persistence: if the created object has an id, try to fetch it from the server
      if (created.quizId.isNotEmpty) {
        try {
          final fetched = await repository.find(created.quizId);
          if (fetched != null) {
            print('[CreateQuizUsecase] Verification successful: fetched created quiz id=${fetched.quizId}');
            return fetched;
          }

          // Retry once after a short delay in case of eventual consistency
          await Future.delayed(const Duration(milliseconds: 500));
          final fetchedRetry = await repository.find(created.quizId);
          if (fetchedRetry != null) {
            print('[CreateQuizUsecase] Verification successful on retry: id=${fetchedRetry.quizId}');
            return fetchedRetry;
          }

          // If not found after retry, consider this an error — resource not reachable
          final msg = 'Creado en respuesta, pero no se pudo verificar la existencia del quiz id=${created.quizId}';
          print('[CreateQuizUsecase] $msg');
          throw Exception(msg);
        } catch (e, st) {
          print('[CreateQuizUsecase] Error during verification: $e');
          print(st);
          rethrow;
        }
      }

      // If created has no id, return what repository returned (could be local-only)
      return created;
    } catch (e, st) {
      print('[CreateQuizUsecase] Error creating quiz: $e');
      print(st);
      rethrow;
    }
  }
}
