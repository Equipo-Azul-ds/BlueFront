import '../../domain/repositories/subscription_repository.dart';

class CancelSubscriptionUseCase {
  final ISubscriptionRepository repository;

  CancelSubscriptionUseCase(this.repository);

  Future<void> execute(String subscriptionId) async {
    if (subscriptionId.trim().isEmpty) {
      throw ArgumentError(
        'Se requiere el ID de suscripción para proceder con la cancelación',
      );
    }

    return await repository.cancelSubscription(subscriptionId);
  }
}
