import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../domain/repositories/single_player_game_repository.dart';
import '../../application/use_cases/single_player_usecases.dart';
import '../blocs/single_player_results_bloc.dart';
import 'single_player_challenge.dart';

const Color purpleDark = Color(0xFF4B0082);
const Color purpleLight = Color(0xFF8A2BE2);

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc.dispose();
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
                        style: const TextStyle(color: Colors.red),
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

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [purpleLight, purpleDark],
                ),
              ),
              child: SafeArea(
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

                    // Animated Card
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
                                  backgroundColor: const Color(0xFF40E0D0),
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
                                    color: purpleDark,
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
                                            : Icons
                                                  .sentiment_dissatisfied_rounded,
                                        color: success
                                            ? Colors.amber
                                            : Colors.redAccent,
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

                    const Spacer(),

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
                                // Navega a la pantalla de desafío. El caso de uso
                                // `StartAttemptUseCase` se encargará de crear un
                                // nuevo intento o reanudar si corresponde.
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
                                foregroundColor: purpleDark,
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
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF40E0D0),
                                foregroundColor: Colors.white,
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
          );
        },
      ),
    );
  }
}
