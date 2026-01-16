import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/multiplayer_session_realtime.dart';


typedef TypedEventHandler<T> = T Function(Map<String, dynamic> payload);

abstract class BaseSessionManager extends ChangeNotifier {
  BaseSessionManager({
    required MultiplayerSessionRealtime realtime,
  }) : realtime = realtime;

 
  @protected
  final MultiplayerSessionRealtime realtime;

  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};


  void registerEventListener<T>({
    required String eventName,
    required TypedEventHandler<T> parser,
    required void Function(T event) handler,
    void Function(Object error)? onError,
  }) {
    _subscriptions[eventName]?.cancel();

    _subscriptions[eventName] = realtime
        .listenToServerEvent<Map<String, dynamic>>(eventName)
        .listen(
          (payload) {
            try {
              final event = parser(payload);
              handler(event);
              notifyListeners();
            } catch (error) {
              _handleEventError(eventName, error, onError);
            }
          },
          onError: (error) {
            _handleEventError(eventName, error, onError);
          },
        );
  }

  /// Cancels a specific event listener.
  void cancelEventListener(String eventName) {
    _subscriptions[eventName]?.cancel();
    _subscriptions.remove(eventName);
  }

  /// Cancels all event listeners managed by this manager.
  void cancelAllEventListeners() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Handles errors from event parsing/handling with consistent logging.
  void _handleEventError(
    String eventName,
    Object error,
    void Function(Object error)? onError,
  ) {
    print('[EVENT] ✗ ERROR processing $eventName: $error');
    onError?.call(error);
  }

  /// Caches a DTO and notifies listeners.
  /// Used by subclasses for brevity.
  void cacheAndNotify<T>(T Function() getter, void Function(T) setter, T value) {
    setter(value);
    notifyListeners();
  }

  @override
  void dispose() {
    cancelAllEventListeners();
    super.dispose();
  }
}
