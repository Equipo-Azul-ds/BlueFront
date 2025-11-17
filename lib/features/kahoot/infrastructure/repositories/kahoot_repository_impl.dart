import '../../domain/entities/kahoot.dart';
import '../../domain/repositories/kahoot_repository.dart';
import '../api/kahoot_api_client.dart';

//Implementacion del repostorio para los Kahoots 
class KahootRepositoryImpl implements KahootRepository{
  final KahootApiClient apiClient;

  KahootRepositoryImpl(): apiClient = KahootApiClient();

  @override
  Future<Kahoot> createKahoot(String title, String?description, String?templateId)async{
    try{
        return await apiClient.createKahoot(title, description, templateId);
      }catch(e){
        throw Exception('Error en repositorio al crear Kahoot: $e');
      }
  }

  @override
  Future<Kahoot> updateKahoot(String id, Map<String,dynamic>updates)async{
    try{
      return await apiClient.uptadeKahoot(id, updates);
    }catch(e){
      throw Exception('Error en repositorio al actualizar Kahoot: $e');
    }
  }

  @override
  Future<Kahoot?> getKahoot(String id) async{
    try{
      return await apiClient.getKahoot(id);
    }catch(e){
      throw Exception('Error en repositorio al obtener un Kahoot:$e');
    }
  }

  @override
  Future<List<Kahoot>> getTemplates()async{
    try{
      return await apiClient.getTemplates();
    }catch (e){
      throw Exception('Error en repositorio al obtener plantillas:$e');
    }
  }
}