import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscribeUserUseCase {
  final ISubscriptionRepository repository;
  SubscribeUserUseCase(this.repository);

  Future<Subscription> execute(String token, String planId) async {
    if (token.isEmpty) throw ArgumentError('Token de sesión requerido');
    return await repository.createSubscription(token: token, planId: planId);
  }
}
