import '../../domain/entities/slide.dart';
import '../../domain/repositories/slide_repository.dart';

//Caso de uso apra obtener todos los slide de un kahoot
class GetSlideUseCase{
  final SlideRepository repository;

  GetSlideUseCase(this.repository);

  Future<List<Slide>> call(String kahootId)async{
    try{
      return await repository.getSlides(kahootId);
    }catch(e){
      throw Exception('Error al obtener los slides: $e');
    }
  }

}