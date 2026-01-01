import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:Trivvy/features/subscriptions/presentation/provider/subscription_provider.dart';
import '../../application/subscription_test_builder.dart';

void main() {
  late SubscriptionTestBuilder builder;

  setUp(() {
    builder = SubscriptionTestBuilder();
  });

  group('SubscriptionProvider Tests', () {
    test('Debe iniciar con estado inicial y no ser premium', () async {
      final provider = SubscriptionProvider(
        subscribeUserUseCase: await builder.buildSubscribeUseCase(),
        getSubscriptionStatusUseCase: await builder.buildGetStatusUseCase(),
        cancelSubscriptionUseCase: await builder.buildCancelUseCase(),
      );

      expect(provider.status, SubscriptionStatus.initial);
      expect(provider.isPremium, false);
    });

    test(
      'Debe pasar a success y activar premium tras una compra exitosa',
      () async {
        // Arrange
        final subscribeUC = await builder
            .givenSubscriptionSucceeds()
            .buildSubscribeUseCase();

        final provider = SubscriptionProvider(
          subscribeUserUseCase: subscribeUC,
          getSubscriptionStatusUseCase: await builder.buildGetStatusUseCase(),
          cancelSubscriptionUseCase: await builder.buildCancelUseCase(),
        );

        // Act
        await provider.purchasePlan('plan_premium');

        // Assert
        expect(provider.status, SubscriptionStatus.success);
        expect(provider.isPremium, true);
        expect(provider.subscription!.planId, 'plan_premium');
      },
    );

    test('Debe manejar errores cuando la suscripción falla', () async {
      // Arrange - Aquí podrías añadir un método 'givenSubscriptionFails' al builder
      when(
        () => builder.repository.createSubscription(
          userId: any(named: 'userId'),
          planId: any(named: 'planId'),
        ),
      ).thenThrow(Exception('Fallo de red'));

      final provider = SubscriptionProvider(
        subscribeUserUseCase: await builder.buildSubscribeUseCase(),
        getSubscriptionStatusUseCase: await builder.buildGetStatusUseCase(),
        cancelSubscriptionUseCase: await builder.buildCancelUseCase(),
      );

      // Act
      await provider.purchasePlan('plan_premium');

      // Assert
      expect(provider.status, SubscriptionStatus.error);
      expect(provider.isPremium, false);
      expect(provider.errorMessage, contains('Fallo de red'));
    });
  });
}
