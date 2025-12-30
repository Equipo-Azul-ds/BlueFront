import 'dart:convert';
import 'package:http/http.dart' as http;

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

    if (response.statusCode != 201) throw Exception('Error al registrar dispositivo'); //
  }

  @override
  Future<void> unregisterDevice(String token) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/notifications/unregister-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"token": token}), // [cite: 4]
    );

    if (response.statusCode != 204) throw Exception('Error al anular registro'); // [cite: 4]
  }
  @override
  Future<List<dynamic>> getNotificationHistory() async {
    final response = await client.get(
      Uri.parse('$baseUrl/notifications'), //
      headers: {'Authorization': 'Bearer YOUR_TOKEN'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body); //
    throw Exception('Error al recuperar historial');
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

// Método real para el Administrador
  @override
  Future<void> sendAdminNotification(String message) async {
    await client.post(
      Uri.parse('$baseUrl/notifications/send-admin'), // Endpoint inferido para admin
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"message": message}),
    );
  }
}