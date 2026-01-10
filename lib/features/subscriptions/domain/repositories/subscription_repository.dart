import '../entities/subscription.dart';

abstract class ISubscriptionRepository {
  Future<Subscription> createSubscription({
    required String userId,
    required String planId,
  });

  Future<void> cancelSubscription(String subscriptionId);

  Future<Subscription?> getSubscriptionStatus(String userId);
}
