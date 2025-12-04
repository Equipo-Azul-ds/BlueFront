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
    // Construye explícitamente la entidad Quiz para su creación.
    // Usar `quizId` vacío para que repository.save() la trate como nueva y haga un POST.
    final uid = Uuid();

    final questions = dto.questions.map((qDto) {
      final qid = 'q_${uid.v4()}';
      final answers = qDto.answers.map((aDto) {
        final aid = 'a_${uid.v4()}';
        // Mapea los campos del DTO (prefiere texto sobre id/ruta de imagen)
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

    // Persiste a través del repositorio (se usará POST porque quizId está vacío)
    try {
      print('[CreateQuizUsecase] Creating quiz -> title="${quizEntity.title}", author=${quizEntity.authorId}, questions=${quizEntity.questions.length}');
      final created = await repository.save(quizEntity);
      print('[CreateQuizUsecase] Repository returned created -> id=${created.quizId}, title="${created.title}"');

      // Verifica la persistencia: si el objeto creado tiene un id, intenta recuperarlo del servidor
      if (created.quizId.isNotEmpty) {
        try {
          final fetched = await repository.find(created.quizId);
          if (fetched != null) {
            print('[CreateQuizUsecase] Verification successful: fetched created quiz id=${fetched.quizId}');
            return fetched;
          }

            // Reintenta una vez tras una breve espera en caso de consistencia eventual
          await Future.delayed(const Duration(milliseconds: 500));
          final fetchedRetry = await repository.find(created.quizId);
          if (fetchedRetry != null) {
            print('[CreateQuizUsecase] Verification successful on retry: id=${fetchedRetry.quizId}');
            return fetchedRetry;
          }

            // Si no se encuentra tras el reintento, considerarlo un error: recurso no accesible
          final msg = 'Creado en respuesta, pero no se pudo verificar la existencia del quiz id=${created.quizId}';
          print('[CreateQuizUsecase] $msg');
          throw Exception(msg);
        } catch (e, st) {
          print('[CreateQuizUsecase] Error during verification: $e');
          print(st);
          rethrow;
        }
      }

      // Si el objeto creado no tiene id, devuelve lo que retornó el repositorio
      // (podría ser un recurso solo local/temporal)
      return created;
    } catch (e, st) {
      print('[CreateQuizUsecase] Error creating quiz: $e');
      print(st);
      rethrow;
    }
  }
}
