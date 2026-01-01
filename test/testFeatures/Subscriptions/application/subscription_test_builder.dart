import 'package:mocktail/mocktail.dart';
import 'package:Trivvy/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:Trivvy/features/subscriptions/application/usecases/subscribe_user_usecase.dart';
import 'package:Trivvy/features/subscriptions/application/usecases/get_subscription_status_usecase.dart';
import 'package:Trivvy/features/subscriptions/application/usecases/cancel_subscription_usecase.dart';
import '../helpers/subscription_mother.dart';

class MockSubscriptionRepository extends Mock
    implements ISubscriptionRepository {}

class SubscriptionTestBuilder {
  final MockSubscriptionRepository _repository = MockSubscriptionRepository();

  // Escenarios de éxito
  SubscriptionTestBuilder givenSubscriptionSucceeds() {
    when(
      () => _repository.createSubscription(
        userId: any(named: 'userId'),
        planId: any(named: 'planId'),
      ),
    ).thenAnswer((_) async => SubscriptionMother.premium());
    return this;
  }

  SubscriptionTestBuilder givenGetStatusReturnsPremium() {
    when(
      () => _repository.getSubscriptionStatus(any()),
    ).thenAnswer((_) async => SubscriptionMother.premium());
    return this;
  }

  // Escenarios de error
  SubscriptionTestBuilder givenGetStatusFails() {
    when(
      () => _repository.getSubscriptionStatus(any()),
    ).thenThrow(Exception('Error de servidor'));
    return this;
  }

  // Builders de Casos de Uso
  Future<SubscribeUserUseCase> buildSubscribeUseCase() async =>
      SubscribeUserUseCase(_repository);
  Future<GetSubscriptionStatusUseCase> buildGetStatusUseCase() async =>
      GetSubscriptionStatusUseCase(_repository);
  Future<CancelSubscriptionUseCase> buildCancelUseCase() async =>
      CancelSubscriptionUseCase(_repository);

  MockSubscriptionRepository get repository => _repository;
}
