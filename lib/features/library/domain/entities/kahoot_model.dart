class Kahoot {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String visibility;
  final String status;
  final List<dynamic>? questions;

  const Kahoot({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.visibility,
    required this.status,
    this.questions,
  });

  factory Kahoot.fromJson(Map<String, dynamic> json) {
    String extractedAuthorId = '';
    String extractedAuthorName = '';

    if (json['author'] != null && json['author'] is Map) {
      extractedAuthorId = (json['author']['id'] ?? '').toString();
      extractedAuthorName = (json['author']['name'] ?? '').toString();
    }

    return Kahoot(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Sin título').toString(),
      description: (json['description'] ?? '').toString(),
      authorId: extractedAuthorId,
      authorName: extractedAuthorName.isEmpty ? 'Anónimo' : extractedAuthorName,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      visibility: (json['visibility'] ?? 'private').toString(),
      status: (json['status'] ?? 'draft').toString(),
      questions: json['questions'] as List<dynamic>?,
    );
  }
}
