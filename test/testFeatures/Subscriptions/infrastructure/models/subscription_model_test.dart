import 'package:flutter_test/flutter_test.dart';
import 'package:Trivvy/features/subscriptions/infrastructure/models/subscription_model.dart';

void main() {
  test('Debe convertir un JSON de la API en una entidad SubscriptionModel', () {
    // Arrange
    final json = {
      'id': 'sub_123',
      'userId': 'user_456',
      'planId': 'plan_premium',
      'status': 'active',
      'expiresAt': '2025-12-31T23:59:59.000Z',
    };

    // Act
    final model = SubscriptionModel.fromJson(json);

    // Assert
    expect(model.id, 'sub_123');
    expect(model.planId, 'plan_premium');
  });
}
