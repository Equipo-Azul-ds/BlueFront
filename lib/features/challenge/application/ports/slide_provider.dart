import '../dtos/single_player_dtos.dart';

/// Permite a la infraestructura exponer DTOs sin contaminar el dominio
abstract class SlideProvider {
  /// Devuelve el DTO de la primera y/o siguiente Slide si aplica
  Future<SlideDTO?> getNextSlideDto(String attemptId);

  /// Devuelve el Index de la respuesta correcta para mostrarla
  Future<int?> getCorrectAnswerIndex(String attemptId, String questionId);

  /// Asegura que el puntero interno de la infraestructura esté sincronizado
  /// con el número de respuestas ya persistidas. Esto evita que la llamada a
  /// `getNextSlideDto` avance la posición incorrectamente cuando reanudamos
  /// un intento existente.
  Future<void> ensurePointerSynced(String attemptId, int expectedIndex);

  /// Devuelve sin avanzar la slide situada en el índice absoluto `index`.
  ///
  /// Útil para que la capa de infraestructura o repositorios puedan
  /// obtener metadatos (p. ej. `slideId`) de una slide concreta sin
  /// modificar el puntero de avance.
  Future<SlideDTO?> peekSlideDto(String attemptId, int index);
}
