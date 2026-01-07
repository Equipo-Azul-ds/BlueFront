import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../Application/DTO/NotificationListResponseDTO.dart';
import '../../Application/DataSource/INotificationDatasource.dart';



class NotificationRemoteDataSource implements INotificationDataSource {
  final String baseUrl;
  final http.Client client;

  NotificationRemoteDataSource({required this.baseUrl, required this.client});

  @override
  Future<void> registerDevice(String token, String deviceType) async {
    final response = await client.post(
      Uri.parse('$baseUrl/notifications/register-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"token": token, "deviceType": deviceType}), //
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Error al registrar dispositivo');
    }
  }

  @override
  Future<void> unregisterDevice(String token) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/notifications/unregister-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"token": token}),
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Error al anular registro'); // [cite: 4]
    }
  }

  @override
  Future<NotificationListResponseDto> getNotificationHistory({
    int limit = 20,
    int page = 1,
  }) async {
    // Construimos la URI con los parámetros de búsqueda
    final uri = Uri.parse('$baseUrl/notifications').replace(
      queryParameters: {
        'limit': limit.toString(),
        'page': page.toString(),
      },
    );

    try {
      print('NotificationRemoteDataSource.getNotificationHistory -> GET $uri');

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // Agregar el token aquí
        },
      );

      if (response.statusCode == 200) {
        final dynamic jsonBody = jsonDecode(response.body);
        return NotificationListResponseDto.fromDynamicJson(jsonBody);
      } else {
        throw Exception('Error al recuperar historial: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getNotificationHistory: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> markAsRead(String id) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/notifications/$id'), //
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"isRead": true}), //
    );

    if (response.statusCode == 200) {
      // Retornamos el JSON para que el Repositorio lo convierta a Entidad
      return jsonDecode(response.body) as Map<String, dynamic>; //
    } else {
      throw Exception('Error al marcar como leída: ${response.statusCode}'); //
    }
  }

  @override
  Future<void> sendAdminNotification(String message) async {
    final response = await client.post(
      Uri.parse('$baseUrl/admin/notifications'), // Endpoint real
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al enviar notificación: ${response.body}');
    }
  }
}