import '../domain/entities/slide.dart';
import '../domain/repositories/slide_repository.dart';

//Caso de uso para duplciar un Slide
class DuplicateSlideUsecase {
  final SlideRepository repository;

  DuplicateSlideUsecase(this.repository);

  Future<Slide>call(String kahootId, String slideId)async{
    return await repository.duplicateSlide(kahootId, slideId);
  }
}