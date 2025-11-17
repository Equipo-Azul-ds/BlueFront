import '../../domain/entities/slide.dart';
import '../../domain/repositories/slide_repository.dart';
import '../api/slide_api_client.dart';

//Implementacion del repositorio de Slide
class SlideRepositoryImpl implements SlideRepository{
  final SlideApiClient apiClient;

  SlideRepositoryImpl(): apiClient = SlideApiClient();

  @override
  Future<Slide> createSlide(String kahootId, Map<String,dynamic>slideData)async{
    try{
      return await apiClient.createSlide(kahootId, slideData);
    }catch(e){
      throw Exception('Error en repositorio al crear un slide: $e');
    }
  }

  @override
  Future<Slide> updateSlide(String kahootId, String slideId, Map<String, dynamic>updates)async{
    try{
      return await apiClient.updateSlide(kahootId, slideId, updates);
    }catch(e){
      throw Exception('Error en repositorio al actualizar un slide: $e');
    }
  }

  @override
  Future<void> deleteSlide(String kahootId, String slideId)async{
    try{
      await apiClient.deleteSlide(kahootId, slideId);
    }catch(e){
      throw Exception('Error en repositorio al elimianr un slide: $e');
    }
  }

  @override  
  Future<Slide> duplicateSlide(String kahootId, String slideId)async{
    try{
      return await apiClient.duplicateSlide(kahootId, slideId);
    }catch(e){
      throw Exception('Error en repositorio al duplicar un slide: $e');
    }
  }

  @override
  Future<List<Slide>> getSlides(String kahootId)async{
    try{
      return await apiClient.getSlide(kahootId);
    }catch(e){
      throw Exception('Error en repositorio al obtener un slide: $e');
    }
  }

}