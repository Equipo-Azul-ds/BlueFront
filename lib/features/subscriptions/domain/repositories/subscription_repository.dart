import '../entities/subscription.dart';

abstract class ISubscriptionRepository {
  Future<Subscription> createSubscription({
    required String token,
    required String planId,
  });

  Future<void> cancelSubscription(String token);

  Future<Subscription?> getSubscriptionStatus(String token);
}
