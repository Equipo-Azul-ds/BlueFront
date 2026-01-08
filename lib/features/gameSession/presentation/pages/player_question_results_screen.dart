import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../controllers/multiplayer_session_controller.dart';
import 'player_question_screen.dart';
import 'player_results_screen.dart';

  /// Muestra el resultado de una pregunta para el jugador y espera la siguiente.
class PlayerQuestionResultsScreen extends StatefulWidget {
  const PlayerQuestionResultsScreen({
    super.key,
    required this.sequenceNumber,
  });

  /// Secuencia de pregunta usada para saber cuándo llega la siguiente.
  final int sequenceNumber;

  @override
  State<PlayerQuestionResultsScreen> createState() => _PlayerQuestionResultsScreenState();
}

class _PlayerQuestionResultsScreenState extends State<PlayerQuestionResultsScreen> {
  bool _navigated = false;
  bool _sessionTerminated = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MultiplayerSessionController>();
    final result = controller.playerResultsDto;

    _checkSessionTermination(controller);

    // Si llega el fin de juego, pasamos al resumen final.
    if (!_navigated && controller.playerGameEndDto != null) {
      _navigate((_) => const PlayerResultsScreen());
    }

    // Si el host lanzó la siguiente pregunta, volvemos al flujo de preguntas.
    if (!_navigated && controller.phase == SessionPhase.question &&
        controller.questionSequence > widget.sequenceNumber) {
      _navigate((_) => const PlayerQuestionScreen());
    }

    if (result == null) {
      return _loadingScaffold();
    }

    final isCorrect = result.isCorrect;
    final points = result.pointsEarned;
    final totalScore = result.totalScore;
    final rank = result.rank;
    final previousRank = result.previousRank;
    final streak = result.streak;
    final progress = result.progress;
    final questionLabel = progress.total > 0
        ? 'Pregunta ${progress.current} de ${progress.total}'
        : 'Pregunta actual';

    final rankDelta = (rank > 0 && previousRank > 0) ? previousRank - rank : 0;
    final rankLabel = rank > 0 ? 'Posición: $rank' : 'Posición no disponible';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.secundary, AppColor.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      questionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultBadge(isCorrect: isCorrect, points: points),
                    const SizedBox(height: 16),
                    _StatCard(
                      label: 'Puntos acumulados',
                      value: '$totalScore pts',
                      icon: Icons.stacked_line_chart,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      label: rankLabel,
                      value: rankDelta == 0
                          ? 'Sin cambio'
                          : (rankDelta > 0
                              ? 'Subiste $rankDelta posiciones'
                              : 'Bajaste ${rankDelta.abs()} posiciones'),
                      icon: Icons.emoji_events_outlined,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      label: 'Racha',
                      value: streak > 0 ? '$streak' : 'Sin racha',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Esperando la siguiente pregunta del anfitrión...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Navega a la pantalla indicada evitando dobles redirecciones.
  void _navigate(WidgetBuilder builder) {
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: builder));
    });
  }

  /// Placeholder mientras se espera el payload de resultados.
  Widget _loadingScaffold() {
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

  /// Sale al inicio si la sesión se cerró o el host abandonó.
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

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.isCorrect, required this.points});

  final bool isCorrect;
  final int points;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColor.success : AppColor.error;
    final icon = isCorrect ? Icons.check_circle : Icons.close_rounded;
    final text = isCorrect ? '¡Correcto!' : 'Respuesta incorrecta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+$points pts',
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
