import 'package:flutter/material.dart';
import 'package:Trivvy/core/widgets/standard_dialogs.dart';

import '../controllers/multiplayer_session_controller.dart';

/// Gestiona errores de conexión/sincronización del socket y muestra un diálogo bloqueante.
class RealtimeErrorHandler {
  Map<String, dynamic>? _handledConnectionError;
  Map<String, dynamic>? _handledSyncError;

  void handle({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required VoidCallback onExit,
  }) {
    final conn = controller.connectionErrorPayload;
    if (conn != null && !identical(conn, _handledConnectionError)) {
      _handledConnectionError = conn;
      final message = conn['message']?.toString() ?? 'Error de conexión.';
      _showBlockingDialog(context, message, onExit);
      return;
    }

    final sync = controller.syncErrorPayload;
    if (sync != null && !identical(sync, _handledSyncError)) {
      _handledSyncError = sync;
      final message = sync['message']?.toString() ?? 'Error de sincronización.';
      _showBlockingDialog(context, message, onExit);
    }
  }

  void reset() {
    _handledConnectionError = null;
    _handledSyncError = null;
  }

  void _showBlockingDialog(
    BuildContext context,
    String message,
    VoidCallback onExit,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showBlockingErrorDialog(
        context: context,
        title: 'Problema de conexión',
        message: message,
        onExit: onExit,
      );
    });
  }
}
