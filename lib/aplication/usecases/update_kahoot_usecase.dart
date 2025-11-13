import '../../domain/entities/kahoot.dart';
import '../../domain/repositories/kahoot_repository.dart';

//Caso de uso para actualizar un Kahoot
class UpdateKahootUsecase{
  final KahootRepository repository;

  UpdateKahootUsecase(this.repository);

  Future<Kahoot>call(String id, Map<String, dynamic>updates)async{
    return await repository.updateKahoot(id, updates);
  }
}