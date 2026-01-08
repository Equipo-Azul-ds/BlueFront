import 'package:flutter/material.dart';

/// Muestra un diálogo bloqueante con un único botón.
Future<void> showBlockingErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onExit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onExit();
          },
          child: const Text('Salir'),
        ),
      ],
    ),
  );
}

/// Muestra un diálogo con opción de reintento.
Future<void> showRetryDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onRetry,
  VoidCallback? onCancel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onCancel?.call();
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onRetry();
          },
          child: const Text('Reintentar'),
        ),
      ],
    ),
  );
}
