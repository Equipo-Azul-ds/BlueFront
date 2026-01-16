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
    final response = await client.post(
      Uri.parse('$baseUrl/user/subscription/premium/'),
      headers: _headers(token),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.trim().isEmpty) {
        return SubscriptionModel(
          id: 'temp_id',
          userId: '',
          planId: 'Premium',
          status: 'active',
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
      }

      final dynamic jsonData = jsonDecode(response.body);
      return SubscriptionModel.fromJson(jsonData as Map<String, dynamic>);
    } else {
      throw Exception('Error al activar suscripción: ${response.body}');
    }
  }

  @override
  Future<void> cancelSubscription(String token) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/user/subscription/free/'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al cancelar suscripción');
    }
  }

  @override
  Future<Subscription?> getSubscriptionStatus(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/user/subscription/status'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) return null;
      final dynamic jsonData = jsonDecode(response.body);
      return SubscriptionModel.fromJson(jsonData as Map<String, dynamic>);
    }
    return null;
  }
}
