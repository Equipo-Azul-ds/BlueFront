import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class GetSubscriptionStatusUseCase {
  final ISubscriptionRepository repository;
  GetSubscriptionStatusUseCase(this.repository);

  Future<Subscription?> execute(String token) async {
    if (token.isEmpty) throw ArgumentError('Token de sesión requerido');
    return await repository.getSubscriptionStatus(token);
  }
}
