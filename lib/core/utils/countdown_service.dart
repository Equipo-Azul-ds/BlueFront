import 'dart:async';

import 'package:flutter/foundation.dart';

/// Servicio de conteo regresivo reutilizable.
class CountdownService {
  Timer? _timer;

  void start({
    required DateTime issuedAt,
    required int timeLimitSeconds,
    required void Function(int remainingSeconds) onTick,
    VoidCallback? onElapsed,
    Duration tickInterval = const Duration(seconds: 1),
  }) {
    cancel();
    _timer = Timer.periodic(tickInterval, (timer) {
      final remaining = computeRemaining(
        issuedAt: issuedAt,
        timeLimitSeconds: timeLimitSeconds,
      );
      onTick(remaining);
      if (remaining <= 0) {
        timer.cancel();
        onElapsed?.call();
      }
    });
  }

  int computeRemaining({required DateTime issuedAt, required int timeLimitSeconds}) {
    final elapsed = DateTime.now().difference(issuedAt).inSeconds;
    return (timeLimitSeconds - elapsed).clamp(0, timeLimitSeconds);
  }

  void cancel() {
    _timer?.cancel();
  }
}
