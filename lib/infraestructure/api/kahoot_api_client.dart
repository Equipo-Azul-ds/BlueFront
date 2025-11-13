import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/kahoot.dart';
import './kahoot_mapper.dart';

//Aqui lo que hacemos un cliente API simulado para los Kahoot, esto despues se debe de cambiar por
//llamadas a nuestra api
class KahootApiClient {
  final String url = 'https://api.kahoot.com';
  
  
  Future<Kahoot> createKahoot(String title, String? description, String? templeId) async{
    final response = await http.post(
      Uri.parse('$url/kahoots'),
      headers:{'Content-Type':'application/json'},
      body: jsonEncode({'title': title, 'description': description, 'templeteId': templeId}),
    );
    if (response.statusCode == 201){
      return KahootMapper.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Error al creal Kahoot: ${response.statusCode}');
    }
  }

  Future<Kahoot> uptadeKahoot(String id, Map<String,dynamic>updates)async{
    final response = await http.patch(
      Uri.parse('$url/kahoot/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
    if (response.statusCode == 200){
      return KahootMapper.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Error al actualizar Kahoot: ${response.body}');
    }
  }

  Future<Kahoot?> getKahoot(String id) async{
    final response = await http.get(Uri.parse('$url/kahoots/$id'));
    if(response.statusCode == 200){
      return KahootMapper.fromJson(jsonDecode(response.body));
    }else if (response.statusCode == 404){
      return null;
    }else {
      throw Exception('Error al obtener kahoot:${response.body}');
    }
  }

  Future<List<Kahoot>> getTemplates()async{
    final response = await http.get(Uri.parse('$url/kahoots/templates'));
    if(response.statusCode == 200){
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json)=>KahootMapper.fromJson(json)).toList();
    }else{
      throw Exception('Error al obtener plantillas: ${response.body}');
    }
  }
}