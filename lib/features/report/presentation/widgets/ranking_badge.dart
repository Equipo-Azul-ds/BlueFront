import 'package:flutter/material.dart';

/// A badge that shows ranking position with trophy icons for top 3.
class RankingBadge extends StatelessWidget {
  const RankingBadge({
    super.key,
    required this.position,
    this.size = RankingBadgeSize.medium,
    this.showLabel = true,
  });

  final int position;
  final RankingBadgeSize size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == RankingBadgeSize.small ? 6 : 10,
        vertical: size == RankingBadgeSize.small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: config.gradient,
        borderRadius: BorderRadius.circular(size == RankingBadgeSize.small ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: config.shadowColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.icon != null) ...[
            Icon(
              config.icon,
              color: Colors.white,
              size: size == RankingBadgeSize.small ? 14 : 18,
            ),
            if (showLabel) const SizedBox(width: 4),
          ],
          if (showLabel)
            Text(
              config.icon != null ? '#$position' : 'Puesto $position',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size == RankingBadgeSize.small ? 11 : 13,
              ),
            ),
        ],
      ),
    );
  }

  _RankingConfig _getConfig() {
    switch (position) {
      case 1:
        return _RankingConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFFFD700),
          icon: Icons.emoji_events,
        );
      case 2:
        return _RankingConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFF8C8C8C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFC0C0C0),
          icon: Icons.emoji_events,
        );
      case 3:
        return _RankingConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFCD7F32),
          icon: Icons.emoji_events,
        );
      default:
        return _RankingConfig(
          gradient: LinearGradient(
            colors: [Colors.grey.shade600, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: Colors.grey,
          icon: null,
        );
    }
  }
}

enum RankingBadgeSize { small, medium, large }

class _RankingConfig {
  final LinearGradient gradient;
  final Color shadowColor;
  final IconData? icon;

  _RankingConfig({
    required this.gradient,
    required this.shadowColor,
    this.icon,
  });
}

/// Animated podium for displaying top 3 players.
class PodiumWidget extends StatelessWidget {
  const PodiumWidget({
    super.key,
    required this.players,
  });

  /// List of (username, score) tuples for top players.
  final List<({String username, int score, int correctAnswers})> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    
    // Reorder for podium: 2nd, 1st, 3rd
    final podiumOrder = <int>[];
    if (players.length >= 2) podiumOrder.add(1); // 2nd place on left
    if (players.isNotEmpty) podiumOrder.add(0);  // 1st place in center
    if (players.length >= 3) podiumOrder.add(2); // 3rd place on right

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: podiumOrder.map((index) {
          final player = players[index];
          final position = index + 1;
          return _PodiumColumn(
            position: position,
            username: player.username,
            score: player.score,
          );
        }).toList(),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.position,
    required this.username,
    required this.score,
  });

  final int position;
  final String username;
  final int score;

  @override
  Widget build(BuildContext context) {
    final height = position == 1 ? 120.0 : (position == 2 ? 90.0 : 70.0);
    final colors = _getColors();
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (position * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with crown for 1st place
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors[0],
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (position == 1)
                  Positioned(
                    top: -14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$score pts',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            // Podium block
            Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getColors() {
    switch (position) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFB8860B)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }
}
