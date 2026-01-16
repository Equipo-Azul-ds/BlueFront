import '../../domain/repositories/subscription_repository.dart';

class CancelSubscriptionUseCase {
  final ISubscriptionRepository repository;
  CancelSubscriptionUseCase(this.repository);

  Future<void> execute(String token) async {
    if (token.isEmpty) throw ArgumentError('Token de sesión requerido');
    return await repository.cancelSubscription(token);
  }
}
