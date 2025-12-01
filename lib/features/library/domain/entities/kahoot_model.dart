class Kahoot {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final DateTime createdAt;
  final String visibility;
  final String status; // "Draft" o "Published" (H7.1)

  const Kahoot({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.createdAt,
    required this.visibility,
    required this.status,
  });

  // Constructor de Serialización JSON
  factory Kahoot.fromJson(Map<String, dynamic> json) {
    return Kahoot(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      authorId: json['authorId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      visibility: json['visibility'] as String,
      status: json['status'] as String,
    );
  }

  // Implementación de la igualdad (para comparación de objetos)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Kahoot &&
        other.id == id &&
        other.title == title &&
        other.authorId == authorId;
  }

  // Implementación del HashCode
  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ authorId.hashCode;
}
