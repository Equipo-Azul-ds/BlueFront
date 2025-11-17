import '../entities/slide.dart';
import '../../../../core/errors/failures.dart';

//Interfaz del repositorio de Slide
abstract class SlideRepository {
  Future<Slide> createSlide(String kahootId, Map<String,dynamic>slideData);
  Future<Slide> updateSlide(String kahootId, String slideId, Map<String,dynamic>updates);
  Future<void> deleteSlide(String kahootId, String slideId);
  Future<Slide> duplicateSlide(String kahootId, String slideId);
  Future<List<Slide>> getSlides(String kahootId);
}
