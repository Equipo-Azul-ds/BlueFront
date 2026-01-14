import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';

import '../../../../../core/constants/colors.dart';
import '../../application/use_cases/report_usecases.dart';
import '../../domain/entities/report_model.dart';
import '../blocs/host_session_report_bloc.dart';
import '../widgets/ranking_badge.dart';
import '../widgets/shimmer_loading.dart';

/// Página dedicada para ver los informes de sesiones que el usuario ha alojado como host.
/// Muestra el ranking completo de jugadores y análisis por pregunta.
class HostSessionReportPage extends StatelessWidget {
  const HostSessionReportPage({super.key, required this.sessionId, this.title});

  final String sessionId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HostSessionReportBloc>(
      create: (context) => HostSessionReportBloc(
        getSessionReportUseCase: context.read<GetSessionReportUseCase>(),
      )..loadSessionReport(sessionId),
      child: Consumer<HostSessionReportBloc>(
        builder: (context, bloc, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.onPrimary,
              title: Text(title ?? 'Informe de Sesión'),
            ),
            body: _buildBody(context, bloc),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HostSessionReportBloc bloc) {
    if (bloc.isLoading && bloc.sessionReport == null) {
      return const SessionReportSkeleton();
    }

    if (bloc.error != null && bloc.sessionReport == null) {
      return _ErrorState(
        message: 'No se pudo cargar el informe de la sesión',
        detail: bloc.error!,
        onRetry: () => bloc.loadSessionReport(sessionId),
      );
    }

    if (bloc.sessionReport != null) {
      return _SessionReportView(report: bloc.sessionReport!);
    }

    return const SizedBox.shrink();
  }
}

class _SessionReportView extends StatelessWidget {
  const _SessionReportView({required this.report});

  final SessionReport report;

  @override
  Widget build(BuildContext context) {
    // Extract top 3 for podium
    final top3 = report.playerRanking.take(3).map((p) => (
      username: p.username,
      score: p.score,
      correctAnswers: p.correctAnswers,
    )).toList();

    final totalPlayers = report.playerRanking.length;
    final avgScore = totalPlayers > 0 
        ? report.playerRanking.map((p) => p.score).reduce((a, b) => a + b) / totalPlayers
        : 0.0;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero header with session info
        StaggeredFadeSlide(
          index: 0,
          child: _HeroCard(
            report: report,
            totalPlayers: totalPlayers,
            avgScore: avgScore,
          ),
        ),
        const SizedBox(height: 20),

        // Podium for top 3
        if (top3.isNotEmpty) ...[
          StaggeredFadeSlide(
            index: 1,
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColor.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Podio de Ganadores',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StaggeredFadeSlide(
            index: 2,
            child: PodiumWidget(players: top3),
          ),
          const SizedBox(height: 24),
        ],

        // Stats overview
        StaggeredFadeSlide(
          index: 3,
          child: _StatsOverview(
            totalPlayers: totalPlayers,
            avgScore: avgScore,
            report: report,
          ),
        ),
        const SizedBox(height: 24),

        // Full ranking section
        StaggeredFadeSlide(
          index: 4,
          child: Row(
            children: [
              const Icon(Icons.leaderboard, color: AppColor.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Ranking Completo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalPlayers jugadores',
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ranking list with animations
        ...report.playerRanking.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          
          return StaggeredFadeSlide(
            index: index + 5,
            staggerDelay: const Duration(milliseconds: 30),
            child: _PlayerRankCard(
              player: player,
              totalQuestions: report.questionAnalysis.length,
            ),
          );
        }),

        const SizedBox(height: 24),

        // Question analysis section
        StaggeredFadeSlide(
          index: report.playerRanking.length + 5,
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColor.accent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Análisis por Pregunta',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        StaggeredFadeSlide(
          index: report.playerRanking.length + 6,
          child: Text(
            'Porcentaje de aciertos de cada pregunta entre todos los participantes',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Question analysis cards
        ...report.questionAnalysis.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          
          return StaggeredFadeSlide(
            index: index + report.playerRanking.length + 7,
            staggerDelay: const Duration(milliseconds: 30),
            child: _QuestionAnalysisCard(
              question: question,
              index: index,
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}

/// Hero card with session overview
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.report,
    required this.totalPlayers,
    required this.avgScore,
  });

  final SessionReport report;
  final int totalPlayers;
  final double avgScore;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColor.primary,
              AppColor.primary.withValues(red: 0.7, green: 0.4, blue: 0.9),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sesión Multijugador',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  _formatDate(report.executionDate),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickStat(
                    icon: Icons.people,
                    label: 'Jugadores',
                    value: totalPlayers.toString(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _QuickStat(
                    icon: Icons.star,
                    label: 'Puntuación Promedio',
                    value: avgScore.toStringAsFixed(0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Stats overview cards
class _StatsOverview extends StatelessWidget {
  const _StatsOverview({
    required this.totalPlayers,
    required this.avgScore,
    required this.report,
  });

  final int totalPlayers;
  final double avgScore;
  final SessionReport report;

  @override
  Widget build(BuildContext context) {
    // Calculate average accuracy across all questions
    final avgAccuracy = report.questionAnalysis.isEmpty
        ? 0.0
        : report.questionAnalysis
                .map((q) => q.correctPercentage)
                .reduce((a, b) => a + b) /
            report.questionAnalysis.length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.quiz,
            label: 'Preguntas',
            value: report.questionAnalysis.length.toString(),
            color: AppColor.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.percent,
            label: 'Precisión Media',
            value: '${(avgAccuracy * 100).toStringAsFixed(0)}%',
            color: AppColor.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            suffix: value.contains('%') ? '%' : '',
            duration: const Duration(milliseconds: 800),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Player ranking card with animations
class _PlayerRankCard extends StatelessWidget {
  const _PlayerRankCard({
    required this.player,
    required this.totalQuestions,
  });

  final PlayerRankingEntry player;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final accuracy = totalQuestions > 0
        ? (player.correctAnswers / totalQuestions * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Could show player detail modal
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Position badge
              if (player.position <= 3)
                RankingBadge(
                  position: player.position,
                  showLabel: false,
                  size: RankingBadgeSize.small,
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${player.position}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 14),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${player.correctAnswers}/$totalQuestions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${accuracy.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: AppColor.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Score with animation
              AnimatedCounter(
                value: player.score,
                suffix: ' pts',
                duration: const Duration(milliseconds: 700),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColor.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Question analysis card with progress bar
class _QuestionAnalysisCard extends StatelessWidget {
  const _QuestionAnalysisCard({
    required this.question,
    required this.index,
  });

  final QuestionAnalysisEntry question;
  final int index;

  @override
  Widget build(BuildContext context) {
    final percentage = question.correctPercentage * 100;
    final color = percentage >= 70
        ? AppColor.success
        : (percentage >= 40 ? Colors.orange : AppColor.error);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColor.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColor.accent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Question text
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar with animated fill
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: question.correctPercentage),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedCounter(
                    value: percentage.round(),
                    suffix: '%',
                    duration: const Duration(milliseconds: 800),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state widget
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromRGBO(
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
      1.0,
    );
  }
}
