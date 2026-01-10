import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'subscription_test_builder.dart';

void main() {
  late SubscriptionTestBuilder builder;

  setUp(() {
    builder = SubscriptionTestBuilder();
  });

  group('SubscribeUserUseCase Tests', () {
    test(
      'Debe llamar al repositorio y crear una suscripción exitosa',
      () async {
        // Arrange
        final useCase = await builder
            .givenSubscriptionSucceeds()
            .buildSubscribeUseCase();
        const userId = 'user_default_test_123';
        const planId = 'plan_premium';

        // Act
        final result = await useCase.execute(userId, planId);

        // Assert
        expect(result.planId, planId);
        expect(result.userId, userId);
        verify(
          () => builder.repository.createSubscription(
            userId: userId,
            planId: planId,
          ),
        ).called(1);
      },
    );

    test(
      'Debe lanzar una excepción si el userId o planId están vacíos',
      () async {
        // Arrange
        final useCase = await builder.buildSubscribeUseCase();

        // Act & Assert
        expect(() => useCase.execute('', 'plan_premium'), throwsArgumentError);
        expect(() => useCase.execute('user_123', ''), throwsArgumentError);
      },
    );
  });
}
