import '../../domain/entities/slide.dart';

//Mapeo para convertir entre JSON y entidad Slide
class SlideMapper {
  //Convierto a JSON la entidad de dominio
  static Slide fromJson(Map<String,dynamic>json){
    return Slide(
      id:json['id'],
      kahootId: json['kahootId'],
      type: json['type'],
      text:json['text'],
      timeLimitSeconds: json['timeLimitSeconds'],
      points: json['points'],
      mediaUrl: json['mediaUrl'],
      options: (json['options']as List<dynamic>?)
          ?.map((opt)=>SlideOptionMapper.fromJson(opt))
          .toList() ?? [],
    );
  }

  //Convierto entidad de domino a JSON
  static Map<String, dynamic> toJson(Slide slide){
    return{
      'id':slide.id,
      'kahootId':slide.kahootId,
      'type':slide.type,
      'text':slide.text,
      'timeLimitSeconds':slide.timeLimitSeconds,
      'points':slide.points,
      'mediaUrl':slide.mediaUrl,
      'option':slide.options.map((opt)=>SlideOptionMapper.toJson(opt)).toList(),
    };
  }

}

//Mappeo para SlideOption
class SlideOptionMapper{
  static SlideOption fromJson(Map<String, dynamic>json){
    return SlideOption(
      text: json['text'], 
      isCorrect: json['isCorrect'],
      mediaUrl: json['mediaUrl']
      );
  }

  static Map<String,dynamic> toJson(SlideOption option){
    return{
      'text':option.text,
      'isCorrect':option.isCorrect,
      'mediaUrl':option.medaUrl
    };
  }
}