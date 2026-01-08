import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../controllers/multiplayer_session_controller.dart';
import 'multiplayer_leaderboard.dart';

/// Resumen final para el jugador al terminar la partida.
class PlayerResultsScreen extends StatefulWidget {
  const PlayerResultsScreen({super.key});

  @override
  State<PlayerResultsScreen> createState() => _PlayerResultsScreenState();
}

class _PlayerResultsScreenState extends State<PlayerResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final ConfettiController _confettiController;
  bool _celebrated = false;
  bool _sessionTerminated = false;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Lanza confetti una sola vez si respondió todo correcto.
  /// Lanza confetti una sola vez si respondió todo correcto.
  void _triggerCelebration(bool perfectRun) {
    if (!perfectRun || _celebrated) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _celebrated) return;
      setState(() => _celebrated = true);
      _confettiController.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consume resumen final del controlador (incluye streak y aciertos).
    final controller = context.watch<MultiplayerSessionController>();
    final PlayerGameEndEvent? summary = controller.playerGameEndDto;
    final nickname = controller.currentNickname ?? 'Jugador';
    final quizTitle = controller.quizTitle ?? 'Trivvy!';

    if (summary == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColor.secundary, AppColor.primary],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    _checkSessionTermination(controller);

    final perfectRun =
      summary.totalQuestions > 0 &&
      summary.correctAnswers == summary.totalQuestions;
    _triggerCelebration(perfectRun);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColor.secundary, AppColor.primary],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          quizTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: FadeTransition(
                            opacity: _fade,
                            child: ScaleTransition(
                              scale: _scale,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 36,
                                      backgroundColor: AppColor.accent,
                                      child: Text(
                                        nickname.isNotEmpty
                                            ? nickname[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      nickname,
                                      style: const TextStyle(
                                        color: AppColor.primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Transform.rotate(
                                          angle:
                                              (math.pi / 20) *
                                              (_cardController.value - 0.5),
                                          child: Icon(
                                          summary.correctAnswers >=
                                              (summary.totalQuestions / 2)
                                            ? Icons.emoji_events_rounded
                                            : Icons
                                                .sentiment_dissatisfied_rounded,
                                            color:
                                                summary.correctAnswers >=
                                                    (summary.totalQuestions / 2)
                                                ? AppColor.success
                                                : AppColor.error,
                                            size: 36,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${summary.correctAnswers} / ${summary.totalQuestions}',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Respuestas correctas',
                                      style: TextStyle(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${summary.totalScore} puntos',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detalle de preguntas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...summary.answers.map(
                                  (answer) => _buildQuestionSummaryRow(
                                    index: answer.index,
                                    wasCorrect: answer.wasCorrect,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    controller.leaveSession();
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColor.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Ir al inicio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MultiplayerLeaderboardScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.accent,
                                    foregroundColor: AppColor.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Ver clasificación',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.04,
                numberOfParticles: 25,
                gravity: 0.08,
                colors: const [
                  Colors.white,
                  AppColor.primary,
                  AppColor.secundary,
                  AppColor.accent,
                  AppColor.success,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sale al inicio si el host cierra la sesión o se pierde la sala.
  void _checkSessionTermination(MultiplayerSessionController controller) {
    if (_sessionTerminated) return;
    final closed = controller.sessionClosedPayload;
    final hostLeft = controller.hostLeftPayload;
    if (closed == null && hostLeft == null) return;
    _sessionTerminated = true;
    final message = closed?['message']?.toString() ??
        hostLeft?['message']?.toString() ??
        'La sesión ha sido cerrada.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }
}

/// Fila de resumen de pregunta en la tarjeta final del jugador.
Widget _buildQuestionSummaryRow({
  required int index,
  required bool? wasCorrect,
}) {
  final statusColor = wasCorrect == null
      ? Colors.white70
      : wasCorrect
      ? AppColor.success
      : AppColor.error;
  final icon = wasCorrect == null
      ? Icons.help_outline
      : wasCorrect
      ? Icons.check_circle
      : Icons.cancel;
  final label = wasCorrect == null
      ? 'Sin responder'
      : wasCorrect
      ? 'Correcta'
      : 'Incorrecta';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Pregunta ${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            Icon(icon, color: statusColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    ),
  );
}
