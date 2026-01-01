import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final String baseUrl;
  final http.Client client;

  SubscriptionRepositoryImpl({required this.baseUrl, required this.client});

  @override
  Future<Subscription> createSubscription({
    required String userId,
    required String planId,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/subscription'),
      body: jsonEncode({'userId': userId, 'planId': planId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return SubscriptionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear suscripción: ${response.statusCode}');
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/subscription/$subscriptionId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cancelar suscripción');
    }
  }

  @override
  Future<Subscription?> getSubscriptionStatus(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/subscription/status/$userId'),
    );
    if (response.statusCode == 200) {
      return SubscriptionModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
