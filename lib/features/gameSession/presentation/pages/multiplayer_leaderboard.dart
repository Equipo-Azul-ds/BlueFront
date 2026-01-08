import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../controllers/multiplayer_session_controller.dart';

/// Clasificación final para jugadores tras ver sus resultados individuales.
class MultiplayerLeaderboardScreen extends StatefulWidget {
  const MultiplayerLeaderboardScreen({super.key});

  @override
  State<MultiplayerLeaderboardScreen> createState() =>
      _MultiplayerLeaderboardScreenState();
}

class _MultiplayerLeaderboardScreenState
    extends State<MultiplayerLeaderboardScreen>
    with SingleTickerProviderStateMixin {

  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    )..play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Sufijo ordinal simple en español (1er, 2do...).
  String _ordinalSuffix(int n) {
    if (n >= 11 && n <= 13) return 'vo';
    switch (n % 10) {
      case 1:
        return 'er';
      case 2:
        return 'do';
      case 3:
        return 'ro';
      default:
        return 'to';
    }
  }

  /// Combina podio del host + resumen propio para construir la tabla.
  List<_LeaderboardRow> _buildLeaderboard(MultiplayerSessionController controller) {
    final quizTitle = controller.quizTitle ?? 'Trivvy!';
    final podium = controller.hostGameEndDto?.finalPodium ?? const <LeaderboardEntry>[];
    final playerSummary = controller.playerGameEndDto;
    final nickname = controller.currentNickname ?? 'Jugador';
    final totalQuestions = playerSummary?.totalQuestions ?? 0;

    final entries = <_LeaderboardRow>[];
    for (final entry in podium) {
      entries.add(_LeaderboardRow(
        name: entry.nickname,
        score: entry.score,
        rank: entry.rank,
        correct: null,
      ));
    }

    // Asegurar que el jugador actual aparezca aunque no esté en el podio.
    if (playerSummary != null) {
      final alreadyIncluded = entries.any((e) => e.name == nickname);
      if (!alreadyIncluded) {
        entries.add(_LeaderboardRow(
          name: nickname,
          score: playerSummary.totalScore,
          rank: playerSummary.rank == 0 ? entries.length + 1 : playerSummary.rank,
          correct: playerSummary.correctAnswers,
        ));
      } else {
        entries.replaceRange(
          0,
          entries.length,
          entries.map((e) {
            if (e.name == nickname) {
              return e.copyWith(
                rank: playerSummary.rank == 0 ? e.rank : playerSummary.rank,
                correct: playerSummary.correctAnswers,
              );
            }
            return e;
          }),
        );
      }
    }

    entries.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }

    return entries
        .map((e) => e.copyWith(totalQuestions: totalQuestions, quizTitle: quizTitle))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MultiplayerSessionController>();
    final quizTitle = controller.quizTitle ?? 'Trivvy!';
    final size = MediaQuery.sizeOf(context);
    final podiumHeight = (size.height * 0.38).clamp(220.0, 360.0);

    final leaderboard = _buildLeaderboard(controller);
    final currentName = controller.currentNickname ?? 'Jugador';
    final userData = leaderboard.firstWhere(
      (player) => player.name == currentName,
      orElse: () => leaderboard.isNotEmpty
          ? leaderboard.first
          : _LeaderboardRow(name: currentName, score: 0, rank: 1, correct: 0),
    );
    final userRank = userData.rank;
    final topPlayers = leaderboard.take(3).toList();

    final List<Widget> podiumColumns = [];
    if (topPlayers.length > 1) {
      podiumColumns.add(_buildPodiumColumn(topPlayers[1], heightFactor: 0.8));
    }
    if (topPlayers.isNotEmpty) {
      podiumColumns.add(_buildPodiumColumn(topPlayers[0], heightFactor: 1.0));
    }
    if (topPlayers.length > 2) {
      podiumColumns.add(_buildPodiumColumn(topPlayers[2], heightFactor: 0.6));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.primary, AppColor.secundary],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          quizTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Resultados',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: podiumHeight,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: podiumColumns,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'Estas en ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '$userRank${_ordinalSuffix(userRank)} lugar',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                TextSpan(
                                  text: ' con ${userData.score} puntos!',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColor.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              'Ir al Inicio',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.04,
                numberOfParticles: 25,
                gravity: 0.1,
                colors: const [
                  Colors.white,
                  AppColor.primary,
                  AppColor.secundary,
                  AppColor.accent,
                  Color(0xFFFFC857),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Columna de podio con nombre, score y posición.
  Widget _buildPodiumColumn(
    _LeaderboardRow player, {
    required double heightFactor,
  }) {
    final int rank = player.rank;
    final Color rankColor = rank == 1
        ? const Color(0xFFFFCC00)
        : rank == 2
        ? const Color(0xFFC0C0C0)
        : const Color(0xFFCD7F32);
    final IconData rankIcon = rank == 1
        ? Icons.looks_one_rounded
        : rank == 2
        ? Icons.looks_two_rounded
        : Icons.looks_3_rounded;
    final int columnHeight = (240 * heightFactor).round();

    final controller = context.read<MultiplayerSessionController>();
    final userName = controller.currentNickname ?? '';
    final bool isUser = player.name == userName;
    final Color nameTagColor = isUser ? AppColor.accent : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: nameTagColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player.name,
              style: TextStyle(
                color: isUser ? Colors.white : AppColor.primary,
                fontWeight: rank == 1 ? FontWeight.w900 : FontWeight.bold,
                fontSize: rank == 1 ? 24 : 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 96,
            height: columnHeight.toDouble(),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColor.accent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(rankIcon, color: Colors.white, size: 28),
                ),
                Column(
                  children: [
                    Text(
                      '${player.score}',
                      style: TextStyle(
                        color: isUser ? AppColor.accent : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (player.correct != null && player.totalQuestions != null)
                      Text(
                        '${player.correct} de ${player.totalQuestions}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrada de leaderboard combinando rank, score y aciertos.
class _LeaderboardRow {
  const _LeaderboardRow({
    required this.name,
    required this.score,
    required this.rank,
    this.correct,
    this.totalQuestions,
    this.quizTitle,
  });

  final String name;
  final int score;
  final int rank;
  final int? correct;
  final int? totalQuestions;
  final String? quizTitle;

  _LeaderboardRow copyWith({
    String? name,
    int? score,
    int? rank,
    int? correct,
    int? totalQuestions,
    String? quizTitle,
  }) {
    return _LeaderboardRow(
      name: name ?? this.name,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      correct: correct ?? this.correct,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      quizTitle: quizTitle ?? this.quizTitle,
    );
  }
}
