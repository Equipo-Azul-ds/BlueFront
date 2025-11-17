import 'package:flutter/material.dart';
import '../../domain/entities/slide.dart';
import '../../application/create_slide_usecase.dart';
import '../../application/delete_slide_usecase.dart';
import '../../application/get_slides_usecase.dart';
import '../../application/update_slide_usecase.dart';
import '../../application/duplicate_slide_usecase.dart';
import '../../infrastructure/repositories/slide_repository_impl.dart';


//BloC para gestionar estado del editor de Slide
class SlideEditorBloc extends ChangeNotifier {
  final SlideRepositoryImpl slideRepository;
  List<Slide> slides = []; //Lista de diapositivas
  Slide? currentSlide; //Slide actual
  bool isLoading = false; //Indicador de carga
  String? errorMessage; //Mensaje de error

  SlideEditorBloc(this.slideRepository);

  //Metodo para cargar toodos los slides de un kahoot
  Future<void> loadSlides(String kahootId) async{
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      slides = await slideRepository.getSlides(kahootId);
    }catch(e){
      errorMessage = 'Error al cargar los slide: $e';
    }finally{
      isLoading = false;
      notifyListeners();
    }
  }

  //Metodo para crear un nuevo Slide
  Future<void> createSlide(String kahootId, Map<String,dynamic>slideData)async{
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final useCase = CreateSlideUsecase(slideRepository);
      final newSlide = await useCase.call(kahootId, slideData);
      slides.add(newSlide);//Agrea el nuevo slide a la lista local
    }catch(e){
      errorMessage = 'Error al crear el slide: $e';
    }finally{
      isLoading = false;
      notifyListeners();
    }
  }

  //Metodo para actualizar un Slide
  Future<void> updateSlide(String kahootId, String slideId, Map<String, dynamic>updates)async{
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final useCase = UpdateSlideUsecase(slideRepository);
      final updatedSlide = await useCase.call(kahootId, slideId, updates);
      final index = slides.indexWhere((s)=>s.id ==slideId);
      if (index!= -1){
        slides[index] = updatedSlide; //Actualiza el slide en la lista local
      }
    }catch(e){
      errorMessage = 'Error al actualizar el slide: $e';
    }finally{
      isLoading = false;
      notifyListeners();
    }
  }

  //Metodo para eliminar un Slide
  Future<void> deleteSlide(String kahootId, String slideId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final useCase = DeleteSlideUsecase(slideRepository);
      await useCase.call(kahootId, slideId);
      slides.removeWhere((s)=>s.id==slideId); //Elimina el slide de la lista local
    }catch(e){
      errorMessage = 'Error al elimianr el slide: $e';
    }finally{
      isLoading = false;
      notifyListeners();
    }
  }

  //Metood para duplicar un Slide
  Future<void> duplicateSlide(String kahootId, String slideId)async{
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final useCase = DuplicateSlideUsecase(slideRepository);
      final duplicatedlide = await useCase.call(kahootId,slideId);
      slides.add(duplicatedlide);
    }catch(e){
      errorMessage = 'Error al duplicar el slide: $e';
    }finally{
      isLoading = false;
      notifyListeners();
    }
  }

  //Metodo para limpiar el estado
  void clear(){
    slides = [];
    currentSlide = null;
    errorMessage = null;
    notifyListeners();
  }
}
