import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/Media.dart';
import '../../domain/repositories/Media_Repository.dart';

class MediaRepositoryImpl {
  final String baseUrl;
  final http.Client client;

  MediaRepositoryImpl({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<void> save(Media media) async{
    final isNew = media.mediaId.isEmpty;
    final url = isNew ? Uri.parse('$baseUrl/media') : Uri.parse('$baseUrl/media/${media.mediaId}');
    final method = isNew ? 'POST' : 'PUT';

    final body = jsonEncode(media.toJson());

    final response = (method == 'POST')
        ? await client.post(url, headers: {'Content-Type': 'application/json'}, body: body)
        : await client.put(url, headers: {'Content-Type': 'application/json'}, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error guardando media: ${response.statusCode}');
    }
  }   

  @override
  Future<Media?>findById(String id)async{
    final response = await client.get(Uri.parse('$baseUrl/media/$id'));

    if (response.statusCode ==200){
      final json = jsonDecode(response.body);
      return Media.fromJson(json);
    }else if(response.statusCode == 404){
      return null;
    }else {
      throw Exception('Error buscando media: ${response.statusCode}');
    }
  }

  @override
  Future<void> delete(String id) async {
    final response = await client.delete(Uri.parse('$baseUrl/media/$id'));

    if (response.statusCode != 200) {
      throw Exception('Error eliminando media: ${response.statusCode}');
    }
  }
}