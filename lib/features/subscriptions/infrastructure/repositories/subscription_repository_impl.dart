import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final String baseUrl;
  final http.Client client;

  SubscriptionRepositoryImpl({required this.baseUrl, required this.client});

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  @override
  Future<Subscription> createSubscription({
    required String token,
    required String planId,
  }) async {
    final url = '$baseUrl/subscription';

    final response = await client.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode({'planId': planId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic jsonData = jsonDecode(response.body);
      final Map<String, dynamic> data =
          (jsonData is Map<String, dynamic> && jsonData.containsKey('data'))
          ? jsonData['data']
          : jsonData;
      return SubscriptionModel.fromJson(data);
    }
    throw Exception('Error Backend: ${response.body}');
  }

  @override
  Future<void> cancelSubscription(String token) async {
    final url = '$baseUrl/subscription';
    final response = await client.delete(
      Uri.parse(url),
      headers: _headers(token),
    );
    print('📩 [BACKEND] Respuesta DELETE (${response.statusCode})');
  }

  @override
  Future<Subscription?> getSubscriptionStatus(String token) async {
    final url = '$baseUrl/subscription';

    final response = await client.get(Uri.parse(url), headers: _headers(token));
    print(
      '📩 [BACKEND] Respuesta GET (${response.statusCode}): ${response.body}',
    );

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) return null;
      final dynamic jsonData = jsonDecode(response.body);
      final Map<String, dynamic> data =
          (jsonData is Map<String, dynamic> && jsonData.containsKey('data'))
          ? jsonData['data']
          : jsonData;
      return SubscriptionModel.fromJson(data);
    }
    return null;
  }
}
