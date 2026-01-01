import 'package:Trivvy/features/subscriptions/domain/entities/subscription.dart';

class SubscriptionMother {
  // Crea una suscripción premium activa
  static Subscription premium() {
    return Subscription(
      id: 'sub_premium_001',
      userId: 'user_default_test_123',
      planId: 'plan_premium',
      status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  // Crea una suscripción gratuita (o estado inicial)
  static Subscription free() {
    return Subscription(
      id: 'sub_free_001',
      userId: 'user_default_test_123',
      planId: 'plan_free',
      status: 'active',
      expiresAt: null,
    );
  }
}
