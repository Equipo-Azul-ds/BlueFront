import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../controllers/multiplayer_session_controller.dart';

/// Podio final para el anfitrión al terminar la partida.
class HostResultsScreen extends StatelessWidget {
  const HostResultsScreen({super.key});

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

    return Scaffold(
      body: Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Podio final',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
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
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: standings.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aún no hay datos del podio.',
                                  style: TextStyle(color: AppColor.primary),
                                ),
                              )
                            : Column(
                                children: [
                                  _Podium(top3: top3),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: _RestOfBoard(entries: rest),
                                  ),
                                ],
                              ),
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

/// Bloque visual del podio (top 3).
class _Podium extends StatelessWidget {
  const _Podium({required this.top3});

  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    final padded = List<LeaderboardEntry>.from(top3);
    padded.sort((a, b) => a.rank.compareTo(b.rank));
    final children = <Widget>[];
    if (padded.length > 1) {
      children.add(_PodiumColumn(entry: padded[1], heightFactor: 0.8));
    }
    if (padded.isNotEmpty) {
      children.add(_PodiumColumn(entry: padded[0], heightFactor: 1.0));
    }
    if (padded.length > 2) {
      children.add(_PodiumColumn(entry: padded[2], heightFactor: 0.65));
    }
    return SizedBox(
      height: 260,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: children,
        ),
      ),
    );
  }
}

/// Columna individual del podio con rank, puntos y nombre.
class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({required this.entry, required this.heightFactor});

  final LeaderboardEntry entry;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank <= 0 ? 1 : entry.rank;
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColor.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              entry.nickname,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 96,
            height: columnHeight.toDouble(),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(rankIcon, color: Colors.white, size: 28),
                ),
                Column(
                  children: [
                    Text(
                      '${entry.score}',
                      style: TextStyle(
                        color: AppColor.primary,
                        fontSize: rank == 1 ? 22 : 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posición $rank',
                      style: const TextStyle(color: Colors.black54),
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

/// Lista del resto del tablero más allá del top 3.
class _RestOfBoard extends StatelessWidget {
  const _RestOfBoard({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 20),
      itemBuilder: (context, index) {
        final standing = entries[index];
        final rank = standing.rank <= 0 ? index + 4 : standing.rank;
        return Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    standing.nickname,
                    style: const TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Puntuación final',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${standing.score} pts',
              style: const TextStyle(
                color: AppColor.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}
