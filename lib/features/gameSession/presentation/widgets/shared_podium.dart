import 'package:flutter/material.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';

import '../../application/dtos/multiplayer_socket_events.dart';

/// Widget de podio compartido que muestra las 3 primeras entradas de la tabla de clasificación con rangos y puntuaciones; utilizado por ambas pantallas de resultados.
class SharedPodium extends StatelessWidget {
  const SharedPodium({
    super.key,
    required this.top3,
    this.currentPlayerRank,
  });

  final List<LeaderboardEntry> top3;
  /// Si se proporciona, resalta el jugador actual en el podio.
  final int? currentPlayerRank;

  @override
  Widget build(BuildContext context) {
    final podiumOrder = List<LeaderboardEntry>.from(top3)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final children = <Widget>[];
    
    if (podiumOrder.length > 1) {
      children.add(PodiumColumn(
        entry: podiumOrder[1],
        heightFactor: 0.8,
        isCurrentPlayer: podiumOrder[1].rank == currentPlayerRank,
      ));
    }
    if (podiumOrder.isNotEmpty) {
      children.add(PodiumColumn(
        entry: podiumOrder[0],
        heightFactor: 1.0,
        isCurrentPlayer: podiumOrder[0].rank == currentPlayerRank,
      ));
    }
    if (podiumOrder.length > 2) {
      children.add(PodiumColumn(
        entry: podiumOrder[2],
        heightFactor: 0.65,
        isCurrentPlayer: podiumOrder[2].rank == currentPlayerRank,
      ));
    }
    
    return SizedBox(
      height: 300,
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

/// Columna individual del podio con icono de rango, puntuación y nombre del jugador; tamaño determinado por factor de altura para visualización escalonada.
class PodiumColumn extends StatelessWidget {
  const PodiumColumn({
    super.key,
    required this.entry,
    required this.heightFactor,
    this.isCurrentPlayer = false,
  });

  final LeaderboardEntry entry;
  final double heightFactor;
  final bool isCurrentPlayer;

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
    final Color nameTagColor = isCurrentPlayer 
        ? AppColor.accent 
        : rank == 1 
            ? AppColor.accent 
            : Colors.white;
    final Color nameTextColor = isCurrentPlayer || rank == 1 
        ? Colors.white 
        : AppColor.primary;
    final Color columnColor = rank == 1
        ? AppColor.accent.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: nameTagColor,
              borderRadius: BorderRadius.circular(6),
              border: isCurrentPlayer 
                  ? Border.all(color: Colors.white, width: 2) 
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrentPlayer) ...[
                  const Icon(Icons.person, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                ],
                Text(
                  entry.nickname,
                  style: TextStyle(
                    color: nameTextColor,
                    fontWeight: rank == 1 ? FontWeight.w900 : FontWeight.bold,
                    fontSize: rank == 1 ? 18 : 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 88,
            height: columnHeight.toDouble(),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: columnColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rank icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(rankIcon, color: Colors.white, size: 24),
                ),
                Column(
                  children: [
                    AnimatedCounter(
                      value: entry.score,
                      style: TextStyle(
                        color: rank == 1 ? Colors.white : AppColor.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pos. $rank',
                      style: TextStyle(
                        color: rank == 1
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white70,
                        fontWeight: FontWeight.w600,
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

/// Muestra entradas de la tabla de clasificación más allá de los 3 primeros jugadores clasificados en una lista desplazable con animaciones escalonadas.
class RestOfLeaderboard extends StatelessWidget {
  const RestOfLeaderboard({
    super.key,
    required this.entries,
    this.currentPlayerRank,
  });

  final List<LeaderboardEntry> entries;
  final int? currentPlayerRank;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No hay más jugadores',
          style: TextStyle(
            color: AppColor.primary.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Resto de jugadores',
            style: TextStyle(
              color: AppColor.primary.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final displayRank = entry.rank <= 0 ? index + 4 : entry.rank;
              final isCurrentPlayer = entry.rank == currentPlayerRank;
              return StaggeredFadeSlide(
                index: index,
                child: LeaderboardRow(
                  entry: entry,
                  displayRank: displayRank,
                  isCurrentPlayer: isCurrentPlayer,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Fila única en la tabla de clasificación que muestra rango, nombre del jugador con indicador de jugador actual opcional y puntuación.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.displayRank,
    this.isCurrentPlayer = false,
  });

  final LeaderboardEntry entry;
  final int displayRank;
  final bool isCurrentPlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isCurrentPlayer 
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6) 
          : EdgeInsets.zero,
      decoration: isCurrentPlayer 
          ? BoxDecoration(
              color: AppColor.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.accent.withValues(alpha: 0.3)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentPlayer 
                  ? AppColor.accent 
                  : AppColor.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$displayRank',
              style: TextStyle(
                color: isCurrentPlayer ? Colors.white : AppColor.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                if (isCurrentPlayer) ...[
                  const Icon(Icons.person, color: AppColor.accent, size: 16),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    entry.nickname,
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: isCurrentPlayer ? FontWeight.w700 : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.score} pts',
            style: TextStyle(
              color: isCurrentPlayer ? AppColor.accent : AppColor.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
