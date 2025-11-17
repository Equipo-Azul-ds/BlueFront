import '../../domain/entities/kahoot.dart';

//Mapeo para convertir entre Json y entidad Kahoot 
class KahootMapper {
  //Convierto JSON a entidad de dominio
  static Kahoot fromJson(Map<String,dynamic> json){
    return Kahoot(
      id:json['id'],
      title:json['title'],
      description: json['description'],
      kahootImage: json['kahootImage'],
      visibility: json['visibility'],
      status:json['status'],
      themes:List<String>.from(json['themes']??[]),
      authorId: json['authorId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }


  //Convierto entidad de dominio a JSON (para hacer el envio al backend)
static Map<String,dynamic> toJson(Kahoot kahoot){
  return{
    'id':kahoot.id,
    'title':kahoot.title,
    'description':kahoot.description,
    'kahootImage':kahoot.kahootImage,
    'visibility':kahoot.visibility,
    'status':kahoot.status,
    'themes':kahoot.themes,
    'authorId':kahoot.authorId,
    'createdAt':kahoot.createdAt.toIso8601String(),
  };
}
}

