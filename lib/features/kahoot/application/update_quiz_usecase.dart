import '../application/dtos/create_quiz_dto.dart';
import '../domain/repositories/QuizRepository.dart';
import '../domain/entities/Quiz.dart';

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

    // 2) Genero el mapa JSON de la nueva representación
    final quizMap = dto.toJson();

  
    quizMap['id'] = quizId;
    
    // 3) Construyo entidad 
    final updatedEntity = Quiz.fromJson(quizMap);

    // 5) Guardo (repo retorna el Quiz actualizado)
    final saved = await repository.save(updatedEntity);
    return saved;
  }
}