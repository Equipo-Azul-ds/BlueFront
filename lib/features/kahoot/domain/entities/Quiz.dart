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
    return Quiz(
      quizId: json['quizId'] ?? json['id'],
      authorId: json['authorId'] ?? (json['author'] != null ? json['author']['authorId'] : null) ?? '',
      title: json['title'],
      description: json['description'],
      visibility: json['visibility'],
      status: json['status'],
      category: json['category'],
      themeId: json['themeId'],
      isLocal: false,
      templateId: json['templateId'],
      coverImageUrl: json['coverImageUrl'] ?? json['coverImage'] ?? json['cover_image'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      questions: (json['questions'] as List).map((q) => Question.fromJson(q as Map<String, dynamic>)).toList(),
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
      // isLocal is client-only and deliberately not sent to backend by default,
      // but we include it here for completeness in local storage scenarios.
      'isLocal': isLocal,
      'createdAt': createdAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

}