import '../../domain/entities/slide.dart';
import '../../domain/repositories/slide_repository.dart';

//Caso de uso para eliminar un Slide
class DeleteSlideUsecase {
  final SlideRepository repository;

  DeleteSlideUsecase(this.repository);

  Future<void>call(String kahootId, String slideId)async{
    await repository.deleteSlide(kahootId, slideId);
  }
}