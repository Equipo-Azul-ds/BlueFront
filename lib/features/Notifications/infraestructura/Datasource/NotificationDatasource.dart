import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../local/secure_storage.dart';
import '../../Application/DTO/AdminNotificacationDTO.dart';
import '../../Application/DTO/NotificationListResponseDTO.dart';
import '../../Dominio/DataSource/INotificationDatasource.dart';




class NotificationRemoteDataSource implements INotificationDataSource {
  final String baseUrl;
  final http.Client client;
  final storage = SecureStorage.instance;

  NotificationRemoteDataSource({required this.baseUrl, required this.client});

  @override
  Future<void> registerDevice(String token, String deviceType) async {
    final tokenid = await storage.read('token');


    final response = await client.post(
      Uri.parse('$baseUrl/notifications/register-device'),
      headers: {'Content-Type': 'application/json',
        //'x-debug-user-id': debugUserId,
        'Authorization': 'Bearer $tokenid',
      },
      body: jsonEncode({"token": token, "deviceType": deviceType}),
    );

    print('--- HTTP RESPONSE ---');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception(
        'Error al registrar dispositivo');
    }
  }

  @override
  Future<void> unregisterDevice(String token) async {
    final tokenid = await storage.read('token');

    final response = await client.delete(
      Uri.parse('$baseUrl/notifications/unregister-device'),
      headers: {'Content-Type': 'application/json',
         'Authorization': 'Bearer $tokenid',},
      body: jsonEncode({"token": token}),
    );

    print('--- HTTP RESPONSE ---');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode != 204) {
      throw Exception(
        'Error al anular registro');
    }
  }

  @override
  Future<NotificationListResponseDto> getNotificationHistory({
    int limit = 20,
    int page = 1,
  }) async {
    final token = await storage.read('token');
    //final userId = await storage.read('userId');
    const String debugUserId = '123e4567-e89b-42d3-a456-426614174000';
    final uri = Uri.parse('$baseUrl/notifications').replace(
      //queryParameters: {
        //'limit': limit.toString(),
        //'page': page.toString(),
      //},

    );

    try {
      print('NotificationRemoteDataSource.getNotificationHistory -> GET $uri');

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json',
          //'x-debug-user-id': debugUserId,
          'Authorization': 'Bearer $token',},
      );

      print('URL: PATCH $uri');
      print('HEADERS: {"Content-Type": "application/json", "user": "$debugUserId"}');
      print('--- HTTP RESPONSE ---');
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedJson = jsonDecode(response.body);
        return NotificationListResponseDto.fromDynamicJson(decodedJson);
      }else {
        throw Exception('Error al recuperar historial: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getNotificationHistory: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> markAsRead(String id) async {
    final token = await storage.read('token');
    final response = await client.patch(
      Uri.parse('$baseUrl/notifications/$id'), //
      headers: {'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',},
      body: jsonEncode({"isRead": true}), //
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>; //
    } else {
      throw Exception('Error al marcar como leída: ${response.statusCode}'); //
    }
  }

  @override
  Future<void> sendAdminNotification(String message) async {
    final response = await client.post(
      Uri.parse('$baseUrl/admin/notifications'),
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

  @override
  Future<Map<String, dynamic>> sendMassNotification({
    required String title,
    required String message,
    required bool toAdmins,
    required bool toRegularUsers,
  }) async {
    final uri = Uri.parse('$baseUrl/backoffice/massNotification');
    final token = await storage.read('token');
    final headers = await _getHeaders();

    final response = await client.post(
      uri, headers: headers,
      /*headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },*/
      body: jsonEncode({
        "title": title,
        "message": message,
        "filters": {
          "toAdmins": toAdmins,
          "toRegularUsers": toRegularUsers,
        }
      }),
    );
    print('URL: POST $uri');
    print('HEADERS: $headers');
    print('BODY: $title $message');

    print('--- HTTP RESPONSE ---');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al enviar notificación masiva: ${response.statusCode}');
    }
  }

  @override
  Future<AdminNotificationListResponseDto> getAdminNotificationHistory({
    int limit = 20,
    int page = 1,
    String? userId,
  }) async {
    final Map<String, String> queryParams = {
      'limit': limit.toString(),
      'page': page.toString(),
      'orderBy': 'createdAt',
      'order': 'desc',
    };
    if (userId != null) queryParams['userId'] = userId;

    final uri = Uri.parse('$baseUrl/backoffice/massNotifications')
        .replace(queryParameters: queryParams);
    final token = await storage.read('token');
    final headers = await _getHeaders();

    final response = await client.get(
      uri, headers: headers
      /*headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },*/
    );
    print('URL: PATCH $uri');
    print('HEADERS: {"Content-Type": "application/json", "user": "$token"}');
    print('--- HTTP RESPONSE ---');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic jsonBody = json.decode(utf8.decode(response.bodyBytes));
      return AdminNotificationListResponseDto.fromDynamicJson(jsonBody);
    } else {
      throw Exception('Error al cargar historial: ${response.statusCode}');
    }
  }

  bool isUsingBackcomun() {
    return !baseUrl.contains('/api');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read('token');
    final bool usingBackcomun = isUsingBackcomun();

    if (usingBackcomun) {
      // Configuración para Backcomun
      return {
        'Content-Type': 'application/json',
        'authorization': token ?? '',
      };
    } else {
      // Configuración para Quizzy
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
  }
}