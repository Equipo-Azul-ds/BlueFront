

import '../../domain/entities/theme.dart';

class ThemeModel extends ThemeEntity {
  const ThemeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.kahootCount,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      kahootCount: json['kahootCount'] as int,
    );
  }

  ThemeEntity toEntity() {
    return ThemeEntity(
      id: id,
      name: name,
      description: description,
      kahootCount: kahootCount,
    );
  }
}