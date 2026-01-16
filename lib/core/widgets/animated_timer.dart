import 'package:flutter/material.dart';
import 'package:Trivvy/core/constants/colors.dart';

/// Animated timer widget with pulse effect and smooth number transitions.
/// Used across different features (single-player, multiplayer, host) for consistent timer UI.
class AnimatedTimer extends StatefulWidget {
  final int timeRemaining;

  const AnimatedTimer({
    Key? key,
    required this.timeRemaining,
  }) : super(key: key);

  @override
  State<AnimatedTimer> createState() => _AnimatedTimerState();
}

class _AnimatedTimerState extends State<AnimatedTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  int _previousTime = 0;

  @override
  void initState() {
    super.initState();
    _previousTime = widget.timeRemaining;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRemaining != widget.timeRemaining) {
      _previousTime = oldWidget.timeRemaining;
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = widget.timeRemaining <= 5;
    final bgColor = isLowTime ? Colors.red.shade400 : Colors.white;
    final textColor = isLowTime ? Colors.white : AppColor.primary;
    final borderColor = isLowTime ? Colors.red.shade200 : Colors.white30;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isLowTime
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: TweenAnimationBuilder<int>(
          tween: IntTween(begin: _previousTime, end: widget.timeRemaining),
          duration: const Duration(milliseconds: 150),
          builder: (context, value, child) {
            return Text(
              '$value',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }
}
