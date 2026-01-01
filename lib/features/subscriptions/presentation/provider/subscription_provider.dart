import 'package:flutter/material.dart';
import '../../application/usecases/subscribe_user_usecase.dart';
import '../../application/usecases/get_subscription_status_usecase.dart';
import '../../application/usecases/cancel_subscription_usecase.dart';
import '../../domain/entities/subscription.dart';

enum SubscriptionStatus { initial, loading, success, error }

class SubscriptionProvider extends ChangeNotifier {
  // Inyectamos el Caso de Uso
  final SubscribeUserUseCase _subscribeUserUseCase;
  final GetSubscriptionStatusUseCase _getSubscriptionStatusUseCase;
  final CancelSubscriptionUseCase _cancelSubscriptionUseCase;

  final String _mockUserId = "user_default_test_123";

  SubscriptionProvider({
    required SubscribeUserUseCase subscribeUserUseCase,
    required GetSubscriptionStatusUseCase getSubscriptionStatusUseCase,
    required CancelSubscriptionUseCase cancelSubscriptionUseCase,
  }) : _subscribeUserUseCase = subscribeUserUseCase,
       _getSubscriptionStatusUseCase = getSubscriptionStatusUseCase,
       _cancelSubscriptionUseCase = cancelSubscriptionUseCase;

  SubscriptionStatus _status = SubscriptionStatus.initial;
  Subscription? _subscription;
  String? _errorMessage;

  // Getters para la UI
  SubscriptionStatus get status => _status;
  Subscription? get subscription => _subscription;
  String? get errorMessage => _errorMessage;
  String get currentUserId => _mockUserId;

  // Propiedad para saber rápido si es premium
  bool get isPremium =>
      _subscription != null &&
      _subscription!.status == 'active' &&
      _subscription!.planId == 'plan_premium';

  // Método para verificar el estado al iniciar la app
  Future<void> checkCurrentStatus() async {
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      _subscription = await _getSubscriptionStatusUseCase.execute(
        currentUserId,
      );
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Método principal para comprar el plan
  Future<void> purchasePlan(String planId) async {
    _status = SubscriptionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Llamamos al caso de uso de la capa de aplicación
      _subscription = await _subscribeUserUseCase.execute(
        currentUserId,
        planId,
      );
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> cancelCurrentSubscription() async {
    if (_subscription == null) return;
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      await _cancelSubscriptionUseCase.execute(_subscription!.id);
      _subscription = await _getSubscriptionStatusUseCase.execute(
        currentUserId,
      );
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
