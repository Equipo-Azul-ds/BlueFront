import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Widget that displays a QR code from a given data string.
/// Typically used to display a session QR token that players can scan.
class QrCodeDisplay extends StatelessWidget {
  final String data;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? label;

  const QrCodeDisplay({
    super.key,
    required this.data,
    this.size = 250,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
        ),
      ],
    );
  }
}
