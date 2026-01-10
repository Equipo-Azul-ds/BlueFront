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
      Uri.parse('$baseUrl/user/$userId/subscription'),
      body: jsonEncode({
        'planId':
            planId, // Ajustado para enviar el planId al endpoint del usuario
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return SubscriptionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al activar suscripción: ${response.statusCode}');
    }
  }

  @override
  Future<void> cancelSubscription(String userId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/user/$userId/subscription'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al cancelar suscripción');
    }
  }

  @override
  Future<Subscription?> getSubscriptionStatus(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/user/$userId/subscription'),
    );

    if (response.statusCode == 200) {
      return SubscriptionModel.fromJson(jsonDecode(response.body));
    }
    return null; // Si no hay suscripción o da error, asumimos Free
  }
}
