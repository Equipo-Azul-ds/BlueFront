import 'package:flutter/material.dart';

/// Widget que anima la entrada de elementos con un efecto de deslizamiento
/// y desvanecimiento escalonado.
/// 
/// Útil para listas donde cada elemento debe aparecer con un pequeño
/// retraso después del anterior.
class StaggeredFadeSlide extends StatefulWidget {
  /// Índice del elemento en la lista (para calcular el retraso).
  final int index;
  
  /// Duración de la animación de cada elemento.
  final Duration duration;
  
  /// Retraso base entre elementos.
  final Duration staggerDelay;
  
  /// Dirección del deslizamiento.
  final Offset slideOffset;
  
  /// Widget hijo a animar.
  final Widget child;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.slideOffset = const Offset(0, 0.15),
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    // Retraso escalonado basado en el índice
    final delay = widget.staggerDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget que anima un número de 0 al valor final con efecto de conteo.
class AnimatedCounter extends StatelessWidget {
  /// Valor final a mostrar.
  final int value;
  
  /// Duración de la animación.
  final Duration duration;
  
  /// Estilo del texto.
  final TextStyle? style;
  
  /// Prefijo opcional (ej: "+").
  final String prefix;
  
  /// Sufijo opcional (ej: " pts").
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix$animatedValue$suffix',
          style: style,
        );
      },
    );
  }
}

/// Widget que revela texto carácter por carácter (efecto typewriter).
class TypewriterText extends StatefulWidget {
  /// Texto a revelar.
  final String text;
  
  /// Duración por carácter.
  final Duration charDuration;
  
  /// Estilo del texto.
  final TextStyle? style;
  
  /// Alineación del texto.
  final TextAlign textAlign;

  const TypewriterText({
    super.key,
    required this.text,
    this.charDuration = const Duration(milliseconds: 50),
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _charAnimation;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.charDuration * widget.text.length;
    
    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );
    
    _charAnimation = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charAnimation,
      builder: (context, child) {
        final visibleChars = _charAnimation.value.clamp(0, widget.text.length);
        return Text(
          widget.text.substring(0, visibleChars),
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}

/// Widget de PIN con animación de flip por dígito.
class AnimatedPinDisplay extends StatelessWidget {
  /// El PIN a mostrar.
  final String pin;
  
  /// Estilo del texto.
  final TextStyle? style;
  
  /// Espaciado entre dígitos.
  final double spacing;

  const AnimatedPinDisplay({
    super.key,
    required this.pin,
    this.style,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final digits = pin.split('');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(digits.length, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: Text(
                  digits[index],
                  style: style,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
