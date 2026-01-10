import 'package:flutter/material.dart';
import 'package:Trivvy/core/widgets/standard_dialogs.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../controllers/multiplayer_session_controller.dart';

/// Gestiona errores de conexión/sincronización del socket y muestra un diálogo bloqueante para prevenir interacción hasta que se reconozca el error.
class RealtimeErrorHandler {
  ConnectionErrorEvent? _handledConnectionError;
  SyncErrorEvent? _handledSyncError;

  /// Maneja errores de conexión o sincronización detectando eventos de error nuevo y mostrando diálogo bloqueante si no se ha manejado aún.
  void handle({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required VoidCallback onExit,
  }) {
    final conn = controller.connectionErrorDto;
    if (conn != null && !identical(conn, _handledConnectionError)) {
      _handledConnectionError = conn;
      final message = conn.message ?? 'Error de conexión.';
      _showBlockingDialog(context, message, onExit);
      return;
    }

    final sync = controller.syncErrorDto;
    if (sync != null && !identical(sync, _handledSyncError)) {
      _handledSyncError = sync;
      final message = sync.message ?? 'Error de sincronización.';
      _showBlockingDialog(context, message, onExit);
    }
  }

  /// Reinicia el caché de error manejado para permitir que el mismo error se muestre nuevamente si vuelve a ocurrir.
  void reset() {
    _handledConnectionError = null;
    _handledSyncError = null;
  }

  /// Muestra un diálogo de error bloqueante que previene interacción hasta que el usuario salga.
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