import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'subscription_test_builder.dart';

void main() {
  late SubscriptionTestBuilder builder;

  setUp(() {
    builder = SubscriptionTestBuilder();
  });

  test('Debe recuperar el estado premium de un usuario específico', () async {
    // Arrange (Preparar)
    final useCase = await builder
        .givenGetStatusReturnsPremium()
        .buildGetStatusUseCase();
    const userId = 'user_default_test_123';

    // Act (Actuar)
    final result = await useCase.execute(userId);

    // Assert (Verificar)
    expect(result!.planId, 'plan_premium');
    expect(result.status, 'active');
    verify(() => builder.repository.getSubscriptionStatus(userId)).called(1);
  });
}
