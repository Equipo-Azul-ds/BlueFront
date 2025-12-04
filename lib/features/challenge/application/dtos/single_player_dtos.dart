// DTOs usados por la capa de infraestructura/presentación para mostrar
// preguntas/options sin introducir dependencias del dominio.
// Estos objetos representan la forma en que la UI recibe la pregunta y las
// opciones desde el proveedor de slides.
class SlideOptionDTO {
  final int index;
  final String? text;
  final String? mediaUrl;

  SlideOptionDTO({required this.index, this.text, this.mediaUrl});
}

// SlideDTO: representa una pregunta completa que se muestra al jugador.
// Contiene el texto de la pregunta, opciones, límite de tiempo y metadatos.
class SlideDTO {
  final String slideId;
  final String questionText;
  final String questionType;
  final int timeLimitSeconds;
  final String? mediaUrl;
  final List<SlideOptionDTO> options;

  SlideDTO({
    required this.slideId,
    required this.questionText,
    required this.questionType,
    required this.timeLimitSeconds,
    required this.options,
    this.mediaUrl,
  });
}
