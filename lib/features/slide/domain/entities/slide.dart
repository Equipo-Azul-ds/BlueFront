// Entidad de dominio para Slide (representa una pregunta)
class Slide {
  final String id;
  final String kahootId;
  final String type; //quiz_single, trueFalse
  final String text;
  final int? timeLimitSeconds;
  final int? points;
  final String? mediaUrl;
  final List<SlideOption> options; // opciones de respuesta

  Slide({
    required this.id,
    required this.kahootId,
    required this.type,
    required this.text,
    this.timeLimitSeconds,
    this.points,
    this.mediaUrl,
    required this.options,
  });
}

//Esta clase representa el tipo de pregunta
class SlideOption {
    final String text;
    final bool isCorrect;
    final String? medaUrl;

    SlideOption({
      required this.text,
      required this.isCorrect,
      this.medaUrl, required mediaUrl,
    });
  }
