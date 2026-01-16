//Entidad de dominio para Kahoot
class Kahoot{
  final String id;
  final String title;
  final String? description;
  final String? kahootImage;
  final String visibility; //publico o privado
  final String status; //borrador o publicado
  final List<String> themes;
  final String author;
  final DateTime createdAt;
  final int? playCount;

  Kahoot({
    required this.id,
    required this.title,
    this.description,
    this.kahootImage,
    required this.visibility,
    required this.status,
    required this.themes,
    required this.author,
    required this.createdAt,
    this.playCount
});

    //Metodo para copiar con cambios (inmutable)
    Kahoot copyWith({
      String? title,
      String? description,
      String? kahootImage,
      String? visibility,
      String? status,
      List<String>? themes,
    }) {
        return Kahoot(
          id: id,
          title: title ?? this.title,
          description: description ?? this.description,
          kahootImage: kahootImage ?? this.kahootImage,
          visibility: visibility ?? this.visibility,
          status: status ?? this.status,
          themes: themes ?? this.themes,
          author: author,
          createdAt: createdAt,
        );
      }
}

