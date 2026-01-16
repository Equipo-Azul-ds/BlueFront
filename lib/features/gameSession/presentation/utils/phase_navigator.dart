import 'package:flutter/material.dart';

import '../controllers/multiplayer_session_controller.dart';
import '../pages/host_results_screen.dart';
import '../pages/player_question_results_screen.dart';
import '../pages/player_results_screen.dart';

/// Centraliza navegación basada en eventos de fase/sincronización mediante monitoreo de cambios de estado del controlador y disparo de transiciones de ruta.
class PhaseNavigator {
  /// Detecta evento de fin de juego del host y navega a pantalla de resultados del host si la secuencia avanzó.
  static int handleHostGameEnd({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required int lastSequence,
  }) {
    final summary = controller.hostGameEndDto;
    if (summary == null) return lastSequence;
    if (controller.hostGameEndSequence == lastSequence) return lastSequence;
    final nextSeq = controller.hostGameEndSequence;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HostResultsScreen()),
      );
    });
    return nextSeq;
  }

  /// Detecta evento de fin de juego del jugador y navega a pantalla de resultados finales del jugador si la secuencia avanzó.
  static int handlePlayerFinalResults({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required int lastSequence,
  }) {
    final summary = controller.playerGameEndDto;
    if (summary == null) return lastSequence;
    if (controller.playerGameEndSequence == lastSequence) return lastSequence;
    final nextSeq = controller.playerGameEndSequence;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlayerResultsScreen()),
      );
    });
    return nextSeq;
  }

   /// Detecta resultados del jugador para la pregunta actual y navega a pantalla de resultados de pregunta del jugador si la secuencia cambió.
  static int handlePlayerQuestionResults({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required int lastSequence,
  }) {
    final results = controller.playerResultsDto;
    final seq = controller.questionSequence;
    if (controller.phase != SessionPhase.results) return lastSequence;
    if (results == null || seq == 0 || seq == lastSequence) return lastSequence;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PlayerQuestionResultsScreen(sequenceNumber: seq),
        ),
      );
    });
    return seq;
  }

  /// Detecta terminación de sesión (sesión cerrada o host salió) y muestra mensaje de despedida; devuelve verdadero si se terminó.
  static bool handleSessionTermination({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required bool alreadyTerminated,
  }) {
    if (alreadyTerminated) return true;
    final closed = controller.sessionClosedDto;
    final hostLeft = controller.hostLeftDto;
    if (closed == null && hostLeft == null) return false;

    final message = closed?.message ?? hostLeft?.message ?? 'La sesión ha sido cerrada.';

    // If the session closed very soon after we joined OR the host appears
    // present (race condition / stale event from server), treat it as
    // transient: show a temporary message and re-evaluate after 2s before
    // forcing the user out. This avoids false-positive ejections when the
    // server sends a late/duplicate close event while the host is still active.

    final joinedAt = controller.sessionJoinedAt;

    final hostPresent = controller.hostLeftDto == null && (
      controller.hostConnectedSuccessDto != null ||
      controller.hostReturnedDto != null ||
      controller.lobbyPlayers.isNotEmpty
    );

    final shouldDelayBecauseRecentJoin = closed != null && joinedAt != null
        ? DateTime.now().difference(joinedAt) < const Duration(seconds: 2)
        : false;

    if (closed != null && (shouldDelayBecauseRecentJoin || hostPresent)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$message — esperando confirmación...')),
        );
      });
      // Re-evaluate after 2s: if the event remains, force the exit.
      Future.delayed(const Duration(seconds: 2), () {
        final stillClosed = controller.sessionClosedDto;
        final hostStillPresent = controller.hostLeftDto == null && controller.lobbyPlayers.isNotEmpty;
        if (stillClosed != null && !hostStillPresent) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(stillClosed.message ?? 'La sesión ha sido cerrada.')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
      return false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
    return true;
  }
}