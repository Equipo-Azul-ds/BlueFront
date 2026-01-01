import 'package:flutter_test/flutter_test.dart';
import 'package:Trivvy/features/subscriptions/domain/entities/subscription.dart';

void main() {
  group('Subscription Entity Tests', () {
    test('Debe crear una instancia de suscripción premium correctamente', () {
      final date = DateTime.now();
      final sub = Subscription(
        id: '1',
        userId: 'u1',
        planId: 'plan_premium',
        status: 'active',
        expiresAt: date,
      );

      expect(sub.planId, 'plan_premium');
      expect(sub.expiresAt, date);
    });

    test('El plan Free debe permitir expiresAt como nulo', () {
      final sub = Subscription(
        id: '2',
        userId: 'u1',
        planId: 'plan_free',
        status: 'active',
        expiresAt: null,
      );

      expect(sub.expiresAt, isNull);
    });
  });
}
