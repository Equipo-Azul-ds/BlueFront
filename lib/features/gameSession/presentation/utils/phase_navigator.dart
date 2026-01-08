import 'package:flutter/material.dart';

import '../controllers/multiplayer_session_controller.dart';
import '../pages/host_results_screen.dart';
import '../pages/player_question_results_screen.dart';
import '../pages/player_results_screen.dart';

/// Centraliza navegación basada en eventos de fase/sincronización.
class PhaseNavigator {
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

  static int handlePlayerFinalResults({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required int lastSequence,
  }) {
    final summary = controller.playerGameEnd;
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

  static bool handleSessionTermination({
    required BuildContext context,
    required MultiplayerSessionController controller,
    required bool alreadyTerminated,
  }) {
    if (alreadyTerminated) return true;
    final closed = controller.sessionClosedPayload;
    final hostLeft = controller.hostLeftPayload;
    if (closed == null && hostLeft == null) return false;
    final message = closed?['message']?.toString() ??
        hostLeft?['message']?.toString() ??
        'La sesión ha sido cerrada.';
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
