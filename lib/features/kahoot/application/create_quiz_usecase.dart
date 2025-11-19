import 'package:provider/provider.dart';

import '../application/dtos/create_quiz_dto.dart';
import '../domain/repositories/QuizRepository.dart';
import '../domain/entities/Quiz.dart';

class CreateQuizUsecase {
  final QuizRepository repository;

  CreateQuizUsecase(this.repository);

  //La idea de esto es que al momento de crear el quiz, mapea el DTO a entidad, 
  //y persiste en el repo. Retorna la entidad quiz que es retornada por el repo/back

  Future<Quiz> run(CreateQuizDto dto) async {
    //1. Preparo el JSON que espera el backend
    final quizMap = dto.toJson(); 

    //2. Construyo la entidad Quiz localmente
    final quizEntity = Quiz.fromJson(quizMap);

    //3. Persite en el repo 
    final created = await repository.save(quizEntity);
    return created;
  }
}
