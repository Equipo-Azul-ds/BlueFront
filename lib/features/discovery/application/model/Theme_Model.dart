import '../../domain/entities/theme.dart';



class ThemeModel extends ThemeEntity {

  const ThemeModel({
    required super.name,
  });


  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      name: json['name'] as String,

    );
  }

  ThemeEntity toEntity() {
    return ThemeEntity(
      name: name,
    );
  }
}