import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:Trivvy/core/constants/colors.dart';
import '../../application/use_cases/single_player_usecases.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../blocs/single_player_results_bloc.dart';
import 'single_player_challenge.dart';

// Pantalla de resultados del intento single-player. Muestra el puntaje,
// número de respuestas correctas y permite iniciar un rematch o volver al
// inicio.
class SinglePlayerChallengeResultsScreen extends StatefulWidget {
  final String gameId;

  const SinglePlayerChallengeResultsScreen({super.key, required this.gameId});

  @override
  State<SinglePlayerChallengeResultsScreen> createState() =>
      _SinglePlayerChallengeResultsScreenState();
}

class _SinglePlayerChallengeResultsScreenState
    extends State<SinglePlayerChallengeResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final SinglePlayerResultsBloc _bloc;
  late final ConfettiController _confettiController;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();

    // Controlador de Animacion para la carta de resultados
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    final repo = Provider.of<SinglePlayerGameRepository>(
      context,
      listen: false,
    );
    final getSummary = Provider.of<GetSummaryUseCase>(context, listen: false);

    _bloc = SinglePlayerResultsBloc(
      repository: repo,
      getSummaryUseCase: getSummary,
    );

    // Cargamos el resumen del intento al iniciar el estado.
    _bloc.load(widget.gameId);

    _controller.forward();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SinglePlayerResultsBloc>.value(
      value: _bloc,
      child: Consumer<SinglePlayerResultsBloc>(
        builder: (context, bloc, _) {
          // Loading
          if (bloc.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Error
          if (bloc.error != null) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Error: ${bloc.error}",
                        style: const TextStyle(color: AppColor.error),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => bloc.retry(widget.gameId),
                        child: const Text("Reintentar"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Summary
          final game = bloc.summaryGame!;
          final nickname = game.playerId;
          final finalScore = game.gameScore.score;
          final totalQuestions = game.totalQuestions;
          final correctAnswers = game.gameAnswers
              .where((qr) => qr.evaluatedAnswer.wasCorrect)
              .length;
          final success = correctAnswers >= (totalQuestions / 2);
          final bool perfectRun =
              totalQuestions > 0 && correctAnswers == totalQuestions;

          if (perfectRun && !_celebrated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _celebrated) return;
              setState(() {
                _celebrated = true;
              });
              _confettiController.play();
            });
          }

          return Scaffold(
            body: Stack(
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
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          const Text(
                            "Resultados",
                            style: TextStyle(
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
                                  vertical: 24.0,
                                  horizontal: 16.0,
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
                                            : "?",
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Transform.rotate(
                                          angle: (math.pi / 20) * _controller.value,
                                          child: Icon(
                                            success
                                                ? Icons.emoji_events_rounded
                                                : Icons.sentiment_dissatisfied_rounded,
                                            color: success
                                                ? AppColor.success
                                                : AppColor.error,
                                            size: 36,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "$correctAnswers / $totalQuestions",
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
                                      "Respuestas correctas",
                                      style: TextStyle(
                                        color: Colors.black.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "$finalScore puntos",
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
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
                                  ...List.generate(totalQuestions, (index) {
                                    final wasCorrect =
                                        index < game.gameAnswers.length
                                            ? game.gameAnswers[index]
                                                .evaluatedAnswer
                                                .wasCorrect
                                            : null;
                                    return _buildQuestionSummaryRow(
                                      index: index,
                                      wasCorrect: wasCorrect,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 20.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // `StartAttemptUseCase` se encargará de crear o
                                    // reanudar un intento cuando se solicite un rematch.
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => SinglePlayerChallengeScreen(
                                          nickname: nickname,
                                          quizId: game.quizId,
                                          totalQuestions: game.totalQuestions,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColor.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    "Rematch",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.accent,
                                    foregroundColor: AppColor.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    "Volver al inicio",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ),
                        ],
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
        },
      ),
    );
  }
}

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
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
