import '../../domain/entities/kahoot.dart';
import '../../domain/repositories/kahoot_repository.dart';

//Caso de uso para obtener Kahoot
class GetKahootUsecase {
  final KahootRepository repository;

  GetKahootUsecase(this.repository);

  Future<Kahoot?> call(String id)async{
    return await repository.getKahoot(id);
  }

}