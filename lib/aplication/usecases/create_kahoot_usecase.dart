import '../../domain/entities/kahoot.dart';
import '../../domain/repositories/kahoot_repository.dart';
import '../../core/errors/failures.dart';

//Este es el caso de usos para crear un Kahoot
class CreateKahootUsecase{
  final KahootRepository  repository;

  CreateKahootUsecase(this.repository);

  Future<Kahoot> call(String title, String? description, String? templateId) async{
    try{
      return await repository.createKahoot(title, description ?? '', templateId ?? '');
    }catch (e){
      throw NetworkFailure();
    }
  }
}
