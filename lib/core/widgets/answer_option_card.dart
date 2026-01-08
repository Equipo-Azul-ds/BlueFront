import 'package:flutter/material.dart';

/// Carta que representa una opción de respuesta a traves de las features de juego sincrono y asincrono.
class AnswerOptionCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final background = selected ? color : color.withValues(alpha: 0.9);
    final resolvedPadding = padding ??
        (layout == Axis.vertical
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(vertical: 16, horizontal: 12));

    Widget buildContent() {
      if (layout == Axis.vertical) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (trailing != null) ...[
              const SizedBox(height: 10),
              trailing!,
            ],
          ],
        );
      }

      return Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
    }

    return ElevatedButton(
      onPressed: disabled ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: resolvedPadding,
        elevation: selected ? 12 : 4,
      ),
      child: buildContent(),
    );
  }
}
