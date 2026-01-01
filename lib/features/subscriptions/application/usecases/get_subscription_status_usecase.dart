import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class GetSubscriptionStatusUseCase {
  final ISubscriptionRepository repository;

  GetSubscriptionStatusUseCase(this.repository);

  Future<Subscription?> execute(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('El ID de usuario no puede estar vacío');
    }

    return await repository.getSubscriptionStatus(userId);
  }
}
