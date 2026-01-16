import 'Question.dart';

class Quiz {
  final String quizId;
  final String authorId;
  String title;
  String description;
  String visibility; // 'public' o 'private'
  String? status; // 'draft' | 'published'
  String? category;
  String themeId;
  // Marca explícita para indicar que este quiz es local/no persistido aún.
  final bool isLocal;
  // Optional local template id (not sent to backend). Used for client-side previews.
  String? templateId;
  String? coverImageUrl;
  final DateTime createdAt;
  List<Question> questions;

  Quiz({
    required this.quizId,
    required this.authorId,
    required this.title,
    required this.description,
    required this.visibility,
    this.status,
    this.category,
    required this.themeId,
    this.templateId,
    this.coverImageUrl,
    this.isLocal = false,
    required this.createdAt,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Robustez para authorId: busca en authorId plano o dentro de objeto author (id o authorId)
    String extractedAuthorId = json['authorId']?.toString() ?? '';
    if (extractedAuthorId.isEmpty && json['author'] != null && json['author'] is Map) {
       final authMap = json['author'];
       extractedAuthorId = (authMap['id'] ?? authMap['authorId'])?.toString() ?? '';
    }

    return Quiz(
      quizId: json['quizId'] ?? json['id'],
      authorId: extractedAuthorId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      visibility: json['visibility'] ?? 'private',
      status: json['status'],
      category: json['category'],
      // Fix: backend returns 'theme' object or 'themeId' string. Handle both and ensure not null.
      themeId: json['themeId'] ?? (json['theme'] != null ? json['theme']['id'] : '') ?? '',
      isLocal: false,
      templateId: json['templateId'],
      // Acepta tanto URL como assetId; si solo viene coverImageId lo guardamos aquí para resolver más adelante.
      coverImageUrl: json['coverImageUrl'] ??
          json['coverImage'] ??
          json['cover_image'] ??
          json['coverImageId']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      questions: (json['questions'] is List) 
          ? (json['questions'] as List).map((q) => Question.fromJson(q as Map<String, dynamic>)).toList() 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'authorId': authorId,
      'title': title,
      'description': description,
      'visibility': visibility,
      'status': status,
      'category': category,
      'themeId': themeId,
      'coverImageUrl': coverImageUrl,
      // isLocal es solo para uso local en el cliente y normalmente no se envía al backend;
      // se incluye aquí por si se guarda el quiz en almacenamiento local.
      'isLocal': isLocal,
      'createdAt': createdAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

}