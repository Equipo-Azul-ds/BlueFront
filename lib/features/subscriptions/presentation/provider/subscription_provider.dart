import 'package:flutter/material.dart';
import '../../application/usecases/subscribe_user_usecase.dart';
import '../../application/usecases/get_subscription_status_usecase.dart';
import '../../application/usecases/cancel_subscription_usecase.dart';
import '../../domain/entities/subscription.dart';

enum SubscriptionStatus { initial, loading, success, error }

class SubscriptionProvider extends ChangeNotifier {
  final SubscribeUserUseCase _subscribeUserUseCase;
  final GetSubscriptionStatusUseCase _getSubscriptionStatusUseCase;
  final CancelSubscriptionUseCase _cancelSubscriptionUseCase;

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

  SubscriptionStatus get status => _status;
  Subscription? get subscription => _subscription;
  String? get errorMessage => _errorMessage;

  bool get isPremium =>
      _subscription != null &&
      _subscription!.planId == 'plan_premium' &&
      _subscription!.status == 'active';

  // CARGAR ESTADO REAL (Se llama al entrar al Perfil)
  Future<void> checkCurrentStatus(String userId) async {
    if (userId.isEmpty) return;
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      _subscription = await _getSubscriptionStatusUseCase.execute(userId);
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // COMPRAR PLAN (Recibe el userId del AuthBloc)
  Future<void> purchasePlan(String userId, String planId) async {
    _status = SubscriptionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = await _subscribeUserUseCase.execute(userId, planId);
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
      rethrow; // Para que la UI pueda mostrar el error
    } finally {
      notifyListeners();
    }
  }

  // CANCELAR (Usa el userId)
  Future<void> cancelCurrentSubscription(String userId) async {
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      await _cancelSubscriptionUseCase.execute(userId);
      _subscription = null;
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
