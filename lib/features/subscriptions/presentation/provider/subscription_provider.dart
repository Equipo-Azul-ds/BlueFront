import 'package:flutter/material.dart';
import '../../domain/entities/subscription.dart';
import '../../application/usecases/subscribe_user_usecase.dart';
import '../../application/usecases/get_subscription_status_usecase.dart';
import '../../application/usecases/cancel_subscription_usecase.dart';

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

  // Ajustado: Compara con el nombre del plan que devuelve el back
  bool get isPremium =>
      _subscription != null &&
      (_subscription!.planId.toLowerCase().contains('premium')) &&
      _subscription!.status == 'active';

  // CARGAR ESTADO (Usando Token)
  Future<void> checkCurrentStatus(String token) async {
    if (token.isEmpty) return;
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      _subscription = await _getSubscriptionStatusUseCase.execute(token);
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // COMPRAR PLAN (Usando Token)
  Future<void> purchasePlan(String token, String planId) async {
    _status = SubscriptionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = await _subscribeUserUseCase.execute(token, planId);
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // CANCELAR (Usando Token)
  Future<void> cancelCurrentSubscription(String token) async {
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      await _cancelSubscriptionUseCase.execute(token);
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
