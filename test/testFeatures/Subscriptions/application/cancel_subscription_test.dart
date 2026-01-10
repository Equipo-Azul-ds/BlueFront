import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'subscription_test_builder.dart';

void main() {
  late SubscriptionTestBuilder builder;

  setUp(() {
    builder = SubscriptionTestBuilder();
  });

  test(
    'Debe ejecutar la cancelación en el repositorio correctamente',
    () async {
      // Arrange
      final useCase = await builder.buildCancelUseCase();
      const subId = 'sub_premium_001';

      // Configuramos el mock para que responda satisfactoriamente
      when(
        () => builder.repository.cancelSubscription(subId),
      ).thenAnswer((_) async => {});

      // Act
      await useCase.execute(subId);

      // Assert
      verify(() => builder.repository.cancelSubscription(subId)).called(1);
    },
  );
}
