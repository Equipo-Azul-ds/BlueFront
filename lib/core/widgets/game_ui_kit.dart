import 'package:flutter/material.dart';
import 'package:Trivvy/core/constants/colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.expanded = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColor.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.expanded = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = 18,
    this.elevation = 10,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: elevation,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
