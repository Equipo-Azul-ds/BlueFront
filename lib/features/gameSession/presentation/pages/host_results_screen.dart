import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../controllers/multiplayer_session_controller.dart';
import '../widgets/shared_podium.dart';

/// Podio final para el anfitrión al terminar la partida.
class HostResultsScreen extends StatefulWidget {
  const HostResultsScreen({super.key});

  @override
  State<HostResultsScreen> createState() => _HostResultsScreenState();
}

class _HostResultsScreenState extends State<HostResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final ConfettiController _confettiController;
  bool _confettiPlayed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    if (_confettiPlayed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _confettiPlayed) return;
      setState(() => _confettiPlayed = true);
      _confettiController.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MultiplayerSessionController>();
    final summary = controller.hostGameEndDto;
    final quizTitle = controller.quizTitle ?? 'Trivvy!';

    if (summary == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColor.primary, AppColor.secundary],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final standings = _buildStandings(summary);
    final totalQuestions =
        summary.totalQuestions ?? controller.hostResultsDto?.progress.total ?? 0;
    final participants = summary.totalParticipants;
    final playersLabel = standings.isEmpty
        ? 'Sin jugadores'
        : 'Juego completado · $participants jugadores';

    final top3 = standings.take(3).toList();
    final rest = standings.skip(3).toList();

    // Trigger confetti on first build with standings
    if (standings.isNotEmpty) {
      _triggerConfetti();
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
                colors: [AppColor.primary, AppColor.secundary],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🏆 Podio final',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    quizTitle,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    playersLabel,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    ),
                                    Text(
                                      totalQuestions > 0
                                          ? '$totalQuestions preguntas'
                                          : 'Total de preguntas no disponible',
                                      style: const TextStyle(color: Colors.white60),
                                    ),
                                  ],
                                ),
                                FilledButton.tonal(
                                  onPressed: () => Navigator.of(context)
                                      .popUntil((route) => route.isFirst),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColor.primary,
                                  ),
                                  child: const Text('Salir'),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: standings.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aún no hay datos del podio.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : Column(
                                  children: [
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: ScaleTransition(
                                        scale: _scaleAnimation,
                                        child: SharedPodium(top3: top3),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Expanded(
                                      child: FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 18,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: RestOfLeaderboard(entries: rest),
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
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.03,
                numberOfParticles: 30,
                gravity: 0.08,
                colors: const [
                  Colors.white,
                  AppColor.primary,
                  AppColor.secundary,
                  AppColor.accent,
                  Color(0xFFFFCC00), // Gold
                  Color(0xFFC0C0C0), // Silver
                  Color(0xFFCD7F32), // Bronze
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Arma standings ordenados a partir del payload de cierre.
  List<LeaderboardEntry> _buildStandings(HostGameEndEvent summary) {
    final podium = List<LeaderboardEntry>.from(summary.finalPodium);
    if (podium.isEmpty && summary.winner != null) {
      podium.add(summary.winner!);
    }
    podium.sort((a, b) => a.rank.compareTo(b.rank));
    return podium;
  }
}


