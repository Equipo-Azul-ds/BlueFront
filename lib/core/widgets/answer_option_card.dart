import 'package:flutter/material.dart';

/// Carta que representa una opción de respuesta a traves de las features de juego sincrono y asincrono.
/// 
/// Incluye animaciones de escala al tocar y transiciones suaves de color.
class AnswerOptionCard extends StatefulWidget {
  const AnswerOptionCard({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.selected = false,
    this.disabled = false,
    this.onTap,
    this.trailing,
    this.layout = Axis.vertical,
    this.padding,
  });

  final String text;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Axis layout;
  final EdgeInsets? padding;

  @override
  State<AnswerOptionCard> createState() => _AnswerOptionCardState();
}

class _AnswerOptionCardState extends State<AnswerOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.disabled) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.disabled) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.disabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.selected 
        ? widget.color 
        : widget.color.withValues(alpha: 0.9);
    final resolvedPadding = widget.padding ??
        (widget.layout == Axis.vertical
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(vertical: 16, horizontal: 12));

    Widget buildContent() {
      if (widget.layout == Axis.vertical) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 28),
            const SizedBox(height: 12),
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(height: 10),
              widget.trailing!,
            ],
          ],
        );
      }

      return Row(
        children: [
          // Ícono con animación de rotación sutil al seleccionar
          AnimatedRotation(
            turns: widget.selected ? 0.05 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(widget.icon, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            AnimatedScale(
              scale: widget.trailing != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              child: widget.trailing!,
            ),
          ],
        ],
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: widget.selected ? 0.4 : 0.2),
                blurRadius: widget.selected ? 16 : 8,
                offset: Offset(0, widget.selected ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.disabled ? null : widget.onTap,
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Padding(
                padding: resolvedPadding,
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white),
                  child: IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: buildContent(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
