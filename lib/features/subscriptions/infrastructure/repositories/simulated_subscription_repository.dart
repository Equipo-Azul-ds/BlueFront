import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class SimulatedSubscriptionRepository implements ISubscriptionRepository {
  @override
  Future<Subscription> createSubscription({
    required String userId,
    required String planId,
  }) async {
    // Simulamos un retraso de red
    await Future.delayed(const Duration(seconds: 2));

    // Devolvemos una entidad ficticia
    return Subscription(
      id: 'sim-123',
      userId: userId,
      planId: planId,
      status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async =>
      await Future.delayed(const Duration(seconds: 1));

  @override
  Future<Subscription?> getSubscriptionStatus(String userId) async => null;
}
