import '../../domain/entities/slide.dart';
import '../../domain/repositories/slide_repository.dart';

//Caso de uso para actualizar un slide
class UpdateSlideUsecasae {
  final SlideRepository repository;

  UpdateSlideUsecasae(this.repository);

  Future<Slide>call(String kahootId, String slideId, Map<String, dynamic>updates)async{
    return await repository.updateSlide(kahootId, slideId, updates);
  }
}