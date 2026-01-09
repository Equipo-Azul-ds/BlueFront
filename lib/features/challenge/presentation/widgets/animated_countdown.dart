import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Trivvy/core/constants/colors.dart';

/// Widget de cuenta regresiva animado con anillo de progreso.
/// 
/// Muestra el tiempo restante con una animación de anillo que se
/// vacía conforme pasa el tiempo. Cambia de color cuando queda
/// poco tiempo.
class AnimatedCountdown extends StatelessWidget {
  /// Tiempo restante en segundos.
  final int timeRemaining;
  
  /// Tiempo total de la pregunta en segundos.
  final int totalTime;
  
  /// Umbral en segundos para mostrar alerta (color rojo).
  final int warningThreshold;

  const AnimatedCountdown({
    super.key,
    required this.timeRemaining,
    required this.totalTime,
    this.warningThreshold = 5,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalTime > 0 ? timeRemaining / totalTime : 0;
    final bool isWarning = timeRemaining <= warningThreshold;
    final Color ringColor = isWarning ? AppColor.error : Colors.white;
    final Color textColor = isWarning ? AppColor.error : AppColor.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: progress, end: progress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, animatedProgress, child) {
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isWarning 
                    ? AppColor.error.withValues(alpha: 0.4) 
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: isWarning ? 16 : 8,
                spreadRadius: isWarning ? 2 : 0,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Anillo de progreso
              Padding(
                padding: const EdgeInsets.all(4),
                child: CustomPaint(
                  painter: _CountdownRingPainter(
                    progress: animatedProgress,
                    color: ringColor,
                    strokeWidth: 4,
                  ),
                ),
              ),
              // Número central con animación de escala en warning
              Center(
                child: AnimatedScale(
                  scale: isWarning ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text('$timeRemaining'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// CustomPainter para dibujar el anillo de progreso.
class _CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Fondo del anillo
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Anillo de progreso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Empieza desde arriba
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
