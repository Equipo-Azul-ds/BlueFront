import 'Question.dart';

class Quiz {
  final String quizId;
  final String authorId;
  String title;
  String description;
  String visibility; // 'public' o 'private'
  String themeId;
  String? coverImageUrl;
  final DateTime createdAt;
  List<Question> questions;

  Quiz({
    required this.quizId,
    required this.authorId,
    required this.title,
    required this.description,
    required this.visibility,
    required this.themeId,
    this.coverImageUrl,
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
      themeId: json['themeId'],
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
      'themeId': themeId,
      'coverImageUrl': coverImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

}