import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscribeUserUseCase {
  final ISubscriptionRepository repository;

  SubscribeUserUseCase(this.repository);

  Future<Subscription> execute(String userId, String planId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError(
        'El ID de usuario es obligatorio para la suscripción',
      );
    }

    if (planId.trim().isEmpty) {
      throw ArgumentError('Debe seleccionar un plan válido');
    }

    return await repository.createSubscription(userId: userId, planId: planId);
  }
}
