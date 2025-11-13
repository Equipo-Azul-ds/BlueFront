import '../../domain/entities/slide.dart';
import '../../domain/repositories/slide_repository.dart';

//Caso de uso para crear un Slide
class CreateSlideUsecase {
  final SlideRepository repository;

  CreateSlideUsecase(this.repository);

  Future<Slide> call(String kahootId, Map<String, dynamic>slideData)async{
    return await repository.createSlide(kahootId, slideData);
  }

}