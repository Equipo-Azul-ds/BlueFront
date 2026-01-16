import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Trivvy/core/constants/colors.dart';

/// Overlay de revisión que muestra el resultado de la respuesta.
/// 
/// Incluye indicador de progreso circular, ícono de resultado,
/// mensaje de feedback y puntos ganados. Se auto-cierra después
/// de [duration] y llama a [onComplete].
class ReviewOverlay extends StatefulWidget {
  /// Duración del periodo de revisión.
  final Duration duration;
  
  /// Si la respuesta fue correcta.
  final bool wasCorrect;
  
  /// Si el tiempo se agotó sin responder.
  final bool wasTimeout;
  
  /// Puntos ganados (solo si fue correcta).
  final int pointsEarned;
  
  /// Callback cuando termina la animación.
  final VoidCallback? onComplete;

  const ReviewOverlay({
    super.key,
    this.duration = const Duration(milliseconds: 2500),
    required this.wasCorrect,
    this.wasTimeout = false,
    this.pointsEarned = 0,
    this.onComplete,
  });

  @override
  State<ReviewOverlay> createState() => _ReviewOverlayState();
}

class _ReviewOverlayState extends State<ReviewOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Haptic feedback based on result
    _triggerResultHaptic();
    
    // Controlador para el progreso circular
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    
    // Controlador para la animación de entrada con rebote
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
    
    // Iniciar animaciones
    _bounceController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _progressController.forward();
    });
  }

  void _triggerResultHaptic() {
    if (widget.wasTimeout) {
      HapticFeedback.heavyImpact();
    } else if (widget.wasCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = widget.wasTimeout
        ? Colors.orange
        : (widget.wasCorrect ? AppColor.success : AppColor.error);
    
    final IconData resultIcon = widget.wasTimeout
        ? Icons.timer_off_rounded
        : (widget.wasCorrect ? Icons.check_rounded : Icons.close_rounded);
    
    final String resultText = widget.wasTimeout
        ? 'Tiempo agotado'
        : (widget.wasCorrect ? '¡Correcto!' : 'Incorrecto');

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) => Container(
          color: Colors.black.withValues(alpha: (0.5 * _fadeAnimation.value).clamp(0.0, 1.0)),

          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícono con anillo de progreso
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          // Anillo de fondo
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation(
                              accentColor.withValues(alpha: 0.2),
                            ),
                          ),
                          // Anillo de progreso animado
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) => CircularProgressIndicator(
                              value: _progressController.value,
                              strokeWidth: 6,
                              valueColor: AlwaysStoppedAnimation(accentColor),
                            ),
                          ),
                          // Círculo de fondo del ícono
                          Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                resultIcon,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Texto de resultado
                    Text(
                      resultText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // Puntos (solo si fue correcta)
                    if (widget.wasCorrect && widget.pointsEarned > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${widget.pointsEarned} pts',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    // Mensaje de timeout
                    if (widget.wasTimeout) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sin responder',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
