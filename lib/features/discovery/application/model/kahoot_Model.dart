import '../../../kahoot/domain/entities/kahoot.dart';
import 'dart:convert'; // Necesario para DateTime.parse



class KahootModel extends Kahoot {
  KahootModel({
    required super.id,
    required super.title,
    super.description,
    super.kahootImage,
    required super.visibility,
    required super.status,
    required super.themes,
    required super.author,
    required super.createdAt,
    super.playCount,
  });

  factory KahootModel.fromJson(Map<String, dynamic> json) {


    final id = json['id'] as String?; // id: uuid_kahoot
    final title = json['title'] as String?;
    final description = json['description'] as String?;
    final coverImageId = json['coverImageId'] as String?; // coverImageId (URL)

    final visibility = json['visibility'] as String?; // visibility: “public” | “private”
    final status = json['status'] as String?; // Status: “draft” | “published”

    final authorJson = json['author'] as Map<String, dynamic>?;
    final authorId = authorJson?['id'] as String?;
    final authorName = authorJson?['name'] as String;

    final createdAtString = json['createdAt'] as String?; // createdAt: ISODate
    final playCount = json['playCount'] as int?;

    // 3. Mapeo de 'category' a 'themes'
    final category = json['category'] as String?;
    final themesList = category != null ? [category] : <String>[];
    final kahootImage = coverImageId;


    if (id == null || title == null || authorId == null || createdAtString == null) {
      throw const FormatException('Kahoot JSON missing required fields: id, title, authorId, createdAt.');
    }

    return KahootModel(
      id: id,
      title: title,
      description: description,
      kahootImage: kahootImage,
      visibility: visibility ?? 'public',
      status: status ?? 'published',
      themes: themesList,
      author: authorName,
      createdAt: DateTime.parse(createdAtString),
      playCount: playCount ?? 0,
    );
  }
}