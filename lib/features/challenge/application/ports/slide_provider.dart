import '../dtos/single_player_dtos.dart';

/// Permite a la infraestructura exponer DTOs sin contaminar el dominio
abstract class SlideProvider {
  /// Devuelve el DTO de la primera y/o siguiente Slide si aplica
  Future<SlideDTO?> getNextSlideDto(String attemptId);

  /// Devuelve el Index de la respuesta correcta para mostrarla
  Future<int?> getCorrectAnswerIndex(String attemptId, String questionId);
}
