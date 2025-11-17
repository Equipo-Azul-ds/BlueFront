import 'package:flutter/material.dart';
import '../../domain/entities/kahoot.dart';
import '../../application/create_kahoot_usecase.dart';
import '../../application/update_kahoot_usecase.dart';
import '../../application/get_kahoot_usecase.dart';
import '../../infrastructure/repositories/kahoot_repository_impl.dart';

//BloC para gestionar el estado del editor de Kahoot
class KahootEditorBloc extends ChangeNotifier{
  final KahootRepositoryImpl kahootRepository;
  Kahoot? currentKahoot; //Kahoot actual en edicion
  bool isLoading = false; //Estado de carga
  String? errorMessage; //Mensaje de error

  KahootEditorBloc(this.kahootRepository);

  //Metodo para crear un nuevo Kahoot
  Future<void> createKahoot(String titile, String? description, String? templateId)async{
    isLoading = true;
    errorMessage = null;
    notifyListeners(); //aqui lo que hace es que notifica que esta cargando

    try{
      final useCase = CreateKahootUsecase(kahootRepository);
      currentKahoot = await useCase.call(titile, description, templateId);
    }catch(e){
      errorMessage = 'Error al crear el  Kahoot: $e';
    }finally{
      isLoading = false;
      notifyListeners(); //aqui lo que hace es que notifica que ya termino de cargar
    }
  }

  //Metodo para cargar un Kahoot existente por ID
  Future<void> loadKahoot(String id)async{
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final useCase = GetKahootUsecase(kahootRepository);
      currentKahoot = await useCase.call(id);
      if(currentKahoot == null){
        errorMessage = 'Ups! el kahoot no existe';
      }  
    }catch(e){
      errorMessage = 'Error al cargar el Kahoot: $e';
    }finally{
      isLoading = false;
      notifyListeners();
    } 
  } 

  //Metodo para actualizar el Kahoot actual
  Future<void> updateKahoot(Map<String, dynamic>updates)async{
    if(currentKahoot ==null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final useCase = UpdateKahootUsecase(kahootRepository);
      currentKahoot = await useCase.call(currentKahoot!.id, updates);
    }catch(e){
      errorMessage = 'Error al actualizar el Kahoot: $e';
    }finally{
      isLoading = false;
      notifyListeners();
    }
  }

  //Metodo para publicar(actualiza estado a 'publico')
  Future<void>publishKahoot()async{
    if(currentKahoot == null) return;

    await updateKahoot({'status':'publico'});
  }

  //Metodo para despublicar(actualiza estado a 'borrador')
  Future<void> unpublishKahoot()async{
    if(currentKahoot == null) return;

    await updateKahoot({'status':'borrador'});
  }

  //Metodo para limpiar el estado 
  void clear(){
    currentKahoot = null;
    errorMessage = null;
    notifyListeners();
  }
}