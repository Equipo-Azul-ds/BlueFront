import '../../domain/entities/slide.dart';
import '../../domain/repositories/slide_repository.dart';

//Caso de uso para actualizar un Slide
class UpdateSlideUsecase{
  final SlideRepository repository;

  UpdateSlideUsecase(this.repository);

  Future<Slide> call(String kahootId, String slideId, Map<String, dynamic>updates)async{
    try{
      return await repository.updateSlide(kahootId, slideId, updates);
    }catch(e){
      throw Exception('Error al actualizar el slide: $e');
    }
  }
}