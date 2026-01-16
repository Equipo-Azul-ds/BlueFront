import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';
import 'package:Trivvy/core/widgets/game_ui_kit.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';
import '../../application/use_cases/single_player_usecases.dart';
import '../../domain/entities/single_player_game.dart';
import '../blocs/single_player_results_bloc.dart';
import 'single_player_challenge.dart';

// Pantalla de resultados del intento single-player. Muestra el puntaje,
// número de respuestas correctas y permite iniciar un rematch o volver al
// inicio.
class SinglePlayerChallengeResultsScreen extends StatefulWidget {
  final String gameId;
  final SinglePlayerGame? initialSummaryGame;

  const SinglePlayerChallengeResultsScreen({
    super.key,
    required this.gameId,
    this.initialSummaryGame,
  });

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
    final getSummary = Provider.of<GetSummaryUseCase>(context, listen: false);

    _bloc = SinglePlayerResultsBloc(getSummaryUseCase: getSummary);
    _bloc.hydrate(widget.initialSummaryGame);

    // Cargamos el resumen del intento al iniciar el estado.
    // Pasamos el quizId del juego inicial para asegurar que se preserve en el resumen.
    final quizId = widget.initialSummaryGame?.quizId;
    _bloc.load(widget.gameId, quizId: quizId);

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
          if (bloc.isLoading && bloc.summaryGame == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Error
          if (bloc.error != null && bloc.summaryGame == null) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Error: ${bloc.error}",
                            style: const TextStyle(color: AppColor.error),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: "Reintentar",
                            icon: Icons.refresh_rounded,
                            onPressed: () => bloc.retry(widget.gameId),
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: "Volver al inicio",
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                          ),
                        ],
                      ),
                    ),
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
          final authBloc = Provider.of<AuthBloc>(context, listen: false);
          final avatarUrl = authBloc.currentUser?.avatarUrl ?? '';
            final correctAnswers = game.totalCorrect ??
              game.gameAnswers
                .where((qr) => qr.evaluatedAnswer.wasCorrect)
                .length;
            final double? accuracyPercentage = game.accuracyPercentage ??
              (totalQuestions > 0
                ? (correctAnswers / totalQuestions) * 100
                : null);
            final accuracyLabel =
              accuracyPercentage != null ? _formatAccuracy(accuracyPercentage) : null;
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
                              child: SurfaceCard(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 16.0,
                                ),
                                borderRadius: 14,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 36,
                                      backgroundColor: AppColor.accent,
                                      backgroundImage: avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl.isEmpty
                                          ? Text(
                                              nickname.isNotEmpty
                                                  ? nickname[0].toUpperCase()
                                                  : "?",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
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
                                    AnimatedCounter(
                                      value: finalScore,
                                      duration: const Duration(milliseconds: 800),
                                      suffix: ' puntos',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (accuracyLabel != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColor.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.speed_rounded,
                                              color: AppColor.primary.withValues(alpha: 0.9),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$accuracyLabel% de precisión',
                                              style: TextStyle(
                                                color: AppColor.primary.withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 20.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: "Rematch",
                                  icon: Icons.restart_alt_rounded,
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => SinglePlayerChallengeScreen(
                                          quizId: game.quizId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SecondaryButton(
                                  label: "Volver al inicio",
                                  icon: Icons.home_rounded,
                                  onPressed: () {
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                  },
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

  String _formatAccuracy(double value) {
    final bool isWhole = value % 1 == 0;
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}
