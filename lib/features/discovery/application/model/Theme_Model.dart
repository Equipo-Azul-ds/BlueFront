import '../../domain/entities/theme.dart';



class ThemeModel extends ThemeVO {

  const ThemeModel({
    required super.name,
  });


  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      name: json['name'] as String,

    );
  }

  ThemeVO toEntity() {
    return ThemeVO(
      name: name,
    );
  }
}