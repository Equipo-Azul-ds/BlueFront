import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:Trivvy/core/constants/colors.dart';

class MultiplayerLeaderboardScreen extends StatefulWidget {
  final String nickname;
  final int finalScore;
  final int totalQuestions;
  final int correctAnswers;

  const MultiplayerLeaderboardScreen({
    super.key,
    required this.nickname,
    required this.finalScore,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  State<MultiplayerLeaderboardScreen> createState() =>
      _MultiplayerLeaderboardScreenState();
}

class _MultiplayerLeaderboardScreenState extends State<MultiplayerLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  static final List<Map<String, dynamic>> _initialMockPlayers = [
    {'name': 'Shima', 'score': 943, 'correct': 2},
    {'name': 'Robyn', 'score': 948, 'correct': 3},
    {'name': 'Mal', 'score': 788, 'correct': 1},
    {'name': 'Nancy', 'score': 1050, 'correct': 3},
    {'name': 'Zane', 'score': 500, 'correct': 1},
  ];

  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5))..play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

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

  List<Map<String, dynamic>> _buildLeaderboard() {
    final list = List<Map<String, dynamic>>.from(_initialMockPlayers)
      ..add({
        'name': widget.nickname,
        'score': widget.finalScore,
        'correct': widget.correctAnswers,
      })
      ..sort((a, b) => b['score'].compareTo(a['score']));

    for (int i = 0; i < list.length; i++) {
      list[i]['rank'] = i + 1;
    }
    return list;
  }

  Map<String, dynamic> _currentUser(List<Map<String, dynamic>> board) {
    return board.firstWhere(
      (player) =>
          player['name'] == widget.nickname &&
          player['score'] == widget.finalScore,
      orElse: () => {
        'name': widget.nickname,
        'score': widget.finalScore,
        'rank': board.length,
        'correct': widget.correctAnswers,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = _buildLeaderboard();
    final userData = _currentUser(leaderboard);
    final userRank = userData['rank'] as int;
    final topPlayers = leaderboard.take(3).toList();

    final List<Widget> podiumColumns = [];
    if (topPlayers.length > 1) {
      podiumColumns.add(
        _buildPodiumColumn(topPlayers[1], heightFactor: 0.8),
      );
    }
    if (topPlayers.isNotEmpty) {
      podiumColumns.add(
        _buildPodiumColumn(topPlayers[0], heightFactor: 1.0),
      );
    }
    if (topPlayers.length > 2) {
      podiumColumns.add(
        _buildPodiumColumn(topPlayers[2], heightFactor: 0.6),
      );
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Trivvy!',
                      style: TextStyle(
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
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
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
                                    text:
                                        ' con ${widget.finalScore} puntos!',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
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

  Widget _buildPodiumColumn(
    Map<String, dynamic> player, {
    required double heightFactor,
  }) {
    final int rank = player['rank'];
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

    final bool isUser =
        player['name'] == widget.nickname &&
        player['score'] == widget.finalScore;
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
              player['name'],
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
                      '${player['score']}',
                      style: TextStyle(
                        color: isUser ? AppColor.accent : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${player['correct']} de ${widget.totalQuestions}',
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
