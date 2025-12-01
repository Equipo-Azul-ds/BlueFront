import '../../../kahoot/domain/entities/kahoot.dart';

class KahootModel extends Kahoot {
  KahootModel({
    required super.id,
    required super.title,
    super.description,
    super.kahootImage,
    required super.visibility,
    required super.status,
    required super.themes,
    required super.authorId,
    required super.createdAt,
    super.playCount,
  });

  factory KahootModel.fromJson(Map<String, dynamic> json) {
    final themesList = (json['themes'] as List<dynamic>?)?.cast<String>() ?? [];

    final authorJson = json['author'] as Map<String, dynamic>?;
    final authorIdValue = authorJson?['id'] as String? ?? 'Desconocido';


    return KahootModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      kahootImage: json['kahootImage'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      status: json['status'] as String? ?? 'published',

      themes: themesList,

      authorId: authorIdValue,
      createdAt: DateTime.parse(json['createdAt'] as String),

      playCount: json['playCount'] as int?,
    );
  }
}