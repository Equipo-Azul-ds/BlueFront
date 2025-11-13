import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/slide.dart';
import './slide_mapper.dart';

//Cliente API para los Slides
class SlideApiClient {
  final String url = 'https:api.kahoot.com';

  Future<Slide> createSlide(String kahootId, Map<String,dynamic> slideData)async{
    final response = await http.post(
      Uri.parse('$url/kahoots/$kahootId/slides'),
      headers: {'Contest/Type':'application/json'},
      body: jsonEncode(slideData),
    );
    if(response.statusCode == 201){
      return SlideMapper.fromJson(jsonDecode((response.body)));
    }else{
      throw Exception('Error al crear un slide: ${response.statusCode}');
    }
  }
  

  Future<Slide> updateSlide(String kahootId, String slideId, Map<String, dynamic> updates)async{
    final response = await http.patch(
      Uri.parse('$url/kahoots/slides/$slideId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
    if(response.statusCode == 201){
      return SlideMapper.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Error al actualizar el slide: ${response.statusCode}');
    }
  }

  Future<void> deleteSlide(String kahootId, String slideId)async{
    final response = await http.delete(Uri.parse('$url/kahoots/$kahootId/slides/$slideId'));
    if(response.statusCode != 204){
      throw Exception('Error al eliminar el slide: ${response.statusCode}');
    }
  }

  Future<Slide> duplicateSlide(String kahootId, String slideId)async{
    final response = await http.post(Uri.parse('$url/kahoots/$kahootId/slides/$slideId/duplicate'));
    if(response.statusCode == 201){
      return SlideMapper.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Error al duplicar Slide: ${response.statusCode}');
    }
  }

  Future<List<Slide>> getSlide(String kahootId)async{
    final response = await http.get(Uri.parse('$url/kahoot/$kahootId/slides'));
    if(response.statusCode ==200){
      final List<dynamic>data= jsonDecode(response.body);
      return data.map((json)=>SlideMapper.fromJson(json)).toList();
    }else{
      throw Exception('Error al obtener los slides: ${response.statusCode}');
    }
  }
}