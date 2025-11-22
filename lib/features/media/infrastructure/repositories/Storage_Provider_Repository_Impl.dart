import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../domain/repositories/Storage_Provider_Repository.dart';

class StorageProviderRepositoryImpl implements StorageProviderRepository {
  final String baseUrl;
  final http.Client client;

  StorageProviderRepositoryImpl({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<String>upload(Uint8List fileBytes, String fileName, String mimeTpye) async{
    final url = Uri.parse('$baseUrl/storage/upload');

    final request = http.MultipartRequest('POST', url)
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType:  http.MediaType.parse(mimeTpye),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['path']; // Ruta relativa devuelta desde backend
    } else {
      throw Exception('Error subiendo archivo: ${response.statusCode}');
    }
  }

  @override
  Future<void> delete(String path) async {
    final response = await client.delete(Uri.parse('$baseUrl/storage/file/$path'));
    if (response.statusCode != 204) {
      throw Exception('Error eliminando archivo: ${response.statusCode}');
    }
  }

  @override
  Future<Uint8List?> get(String path) async {
    final response = await client.get(Uri.parse('$baseUrl/storage/file/$path'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Error obteniendo archivo: ${response.statusCode}');
  }
}