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

  bool get isPremium {
    if (_subscription == null) return false;
    final plan = _subscription!.planId.toUpperCase();
    final status = _subscription!.status.toLowerCase();
    return plan.contains('PREMIUM') && status == 'active';
  }

  // Limpiar datos al cerrar sesión
  void clear() {
    _subscription = null;
    _status = SubscriptionStatus.initial;
    notifyListeners();
  }

  // Método para centralizar la actualización desde el servidor
  Future<void> _refreshStatusFromServer(String token) async {
    _subscription = await _getSubscriptionStatusUseCase.execute(token);
    notifyListeners();
  }

  Future<void> checkCurrentStatus(String token) async {
    if (token.isEmpty) {
      return;
    }
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      await _refreshStatusFromServer(token);
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> purchasePlan(String token, String planId) async {
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      await _subscribeUserUseCase.execute(token, planId);
      // Tras éxito en POST, forzamos GET para sincronizar
      await _refreshStatusFromServer(token);
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> cancelCurrentSubscription(String token) async {
    _status = SubscriptionStatus.loading;
    notifyListeners();
    try {
      await _cancelSubscriptionUseCase.execute(token);
      // Tras éxito en DELETE, forzamos GET para confirmar que el back ahora devuelve FREE
      await _refreshStatusFromServer(token);
      _status = SubscriptionStatus.success;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
