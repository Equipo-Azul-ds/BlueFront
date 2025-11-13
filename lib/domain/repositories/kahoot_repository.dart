import '../entities/kahoot.dart';
import '../../core/errors/failures.dart';

//Interfaz del repositorio para kahoot
abstract class KahootRepository {
  Future<Kahoot> createKahoot(String title, String description, String? templateId);
  Future<Kahoot> updateKahoot(String id, Map<String, dynamic>updates);
  Future<Kahoot?> getKahoot(String id);
  Future<List<Kahoot>> getTemplates(); //para obtener las plantillas
}