import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';
import 'package:confetti/confetti.dart';

import '../../../../../core/constants/colors.dart';
import '../../application/use_cases/report_usecases.dart';
import '../../domain/entities/report_model.dart';
import '../blocs/report_detail_bloc.dart';
import '../widgets/ranking_badge.dart';
import '../widgets/shimmer_loading.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReportDetailBloc>(
      create: (context) => ReportDetailBloc(
        getSessionReportUseCase: context.read<GetSessionReportUseCase>(),
        getMultiplayerResultUseCase: context.read<GetMultiplayerResultUseCase>(),
        getSingleplayerResultUseCase: context.read<GetSingleplayerResultUseCase>(),
      )..loadFromSummary(summary),
      child: Consumer<ReportDetailBloc>(
        builder: (context, bloc, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.onPrimary,
              title: Text(summary.title),
            ),
            body: _buildBody(context, bloc),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReportDetailBloc bloc) {
    if (bloc.isLoading && bloc.personalResult == null && bloc.sessionReport == null) {
      return const PersonalResultSkeleton();
    }

    if (bloc.error != null && bloc.personalResult == null && bloc.sessionReport == null) {
      return _ErrorState(
        message: 'No se pudo cargar el reporte',
        detail: bloc.error!,
        onRetry: () => bloc.loadFromSummary(summary),
      );
    }

    if (bloc.personalResult != null) {
      return _PersonalResultView(result: bloc.personalResult!, type: summary.gameType);
    }

    if (bloc.sessionReport != null) {
      return _SessionReportView(report: bloc.sessionReport!);
    }

    return const SizedBox.shrink();
  }
}

class _PersonalResultView extends StatefulWidget {
  const _PersonalResultView({required this.result, required this.type});

  final PersonalResult result;
  final GameType type;

  @override
  State<_PersonalResultView> createState() => _PersonalResultViewState();
}

class _PersonalResultViewState extends State<_PersonalResultView> {
  late ConfettiController _confettiController;
  bool _confettiFired = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Fire confetti for high accuracy (>= 80%)
    final accuracy = widget.result.totalQuestions == 0
        ? 0.0
        : (widget.result.correctAnswers / widget.result.totalQuestions) * 100;
    
    if (accuracy >= 80 && !_confettiFired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confettiController.play();
          _confettiFired = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double accuracy = widget.result.totalQuestions == 0
        ? 0.0
        : ((widget.result.correctAnswers / widget.result.totalQuestions) * 100).clamp(0.0, 100.0).toDouble();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tarjeta de resumen con animaciones
            StaggeredFadeSlide(
              index: 0,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Tag(label: widget.type == GameType.singleplayer ? 'Singleplayer' : 'Multiplayer', color: AppColor.primary),
                          const SizedBox(width: 8),
                          _AnimatedScoreTag(score: widget.result.finalScore),
                          if (widget.result.rankingPosition != null) ...[
                            const SizedBox(width: 8),
                            RankingBadge(position: widget.result.rankingPosition!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.result.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Stats con animaciones
                      Row(
                        children: [
                          Expanded(
                            child: _AnimatedStatCard(
                              icon: Icons.check_circle_outline,
                              label: 'Correctas',
                              value: widget.result.correctAnswers,
                              total: widget.result.totalQuestions,
                              color: AppColor.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AnimatedAccuracyCard(
                              accuracy: accuracy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tiempo promedio: ${_formatMs(widget.result.averageTimeMs)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      // Celebration message for high accuracy
                      if (accuracy >= 80) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade100,
                                Colors.orange.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.celebration, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                accuracy >= 90 ? '¡Excelente trabajo!' : '¡Muy bien!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.celebration, color: Colors.orange.shade700),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredFadeSlide(
              index: 1,
              child: const Text(
                'Preguntas respondidas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...widget.result.questionResults.asMap().entries.map((entry) => 
              StaggeredFadeSlide(
                index: entry.key + 2,
                staggerDelay: const Duration(milliseconds: 50),
                child: _QuestionTile(entry: entry.value),
              ),
            ),
          ],
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '—';
    final seconds = (ms / 1000).toStringAsFixed(1);
    return '$seconds s';
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
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title card
        StaggeredFadeSlide(
          index: 0,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tag(label: 'Sesión', color: AppColor.primary),
                  const SizedBox(height: 10),
                  Text(
                    report.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(report.executionDate),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Podium for top 3
        if (top3.isNotEmpty) ...[
          StaggeredFadeSlide(
            index: 1,
            child: const Text(
              '🏆 Podio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          StaggeredFadeSlide(
            index: 2,
            child: PodiumWidget(players: top3),
          ),
          const SizedBox(height: 20),
        ],
        // Full ranking
        StaggeredFadeSlide(
          index: 3,
          child: const Text(
            'Ranking completo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ...report.playerRanking.asMap().entries.map((entry) {
          final p = entry.value;
          return StaggeredFadeSlide(
            index: entry.key + 4,
            staggerDelay: const Duration(milliseconds: 40),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: p.position <= 3
                    ? RankingBadge(position: p.position, showLabel: false, size: RankingBadgeSize.small)
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          '${p.position}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                title: Text(p.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${p.correctAnswers} correctas'),
                trailing: AnimatedCounter(
                  value: p.score,
                  suffix: ' pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        // Question analysis
        StaggeredFadeSlide(
          index: report.playerRanking.length + 4,
          child: const Text(
            'Análisis por pregunta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ...report.questionAnalysis.asMap().entries.map((entry) {
          final q = entry.value;
          final percentage = q.correctPercentage * 100;
          final color = percentage >= 70 
              ? AppColor.success 
              : (percentage >= 40 ? Colors.orange : AppColor.error);
          
          return StaggeredFadeSlide(
            index: entry.key + report.playerRanking.length + 5,
            staggerDelay: const Duration(milliseconds: 40),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${q.questionIndex + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.questionText,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.entry});

  final QuestionResultEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.isCorrect ? Icons.check_circle : Icons.cancel;
    final color = entry.isCorrect ? AppColor.success : AppColor.error;
    
    // Per API spec: answerText and answerMediaIds are arrays (for multiple choice)
    // They are mutually exclusive - answers have either text OR image
    final hasTextAnswers = entry.answerText.isNotEmpty;
    final hasImageAnswers = entry.answerMediaIds.isNotEmpty;
    final hasNoAnswer = !hasTextAnswers && !hasImageAnswers;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.questionText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.isCorrect ? 'Correcta' : 'Incorrecta',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Selected answers section
            Row(
              children: [
                Icon(Icons.reply, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Tu respuesta:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (hasNoAnswer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sin respuesta',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              )
            else if (hasTextAnswers)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.answerText.map((text) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: color.darken(0.1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              )
            else if (hasImageAnswers)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.answerMediaIds.map((mediaUrl) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            const SizedBox(height: 8),
            // Time taken footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatMs(entry.timeTakenMs),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '—';
    final seconds = (ms / 1000).toStringAsFixed(1);
    return '$seconds s';
  }
}

/// Widget de puntuación con animación de conteo.
class _AnimatedScoreTag extends StatelessWidget {
  const _AnimatedScoreTag({required this.score});
  
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.secundary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.secundary.withValues(alpha: 0.5)),
      ),
      child: AnimatedCounter(
        value: score,
        suffix: ' pts',
        duration: const Duration(milliseconds: 1000),
        style: TextStyle(
          color: AppColor.secundary.darken(0.1),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Tarjeta de estadística con contador animado.
class _AnimatedStatCard extends StatelessWidget {
  const _AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });
  
  final IconData icon;
  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Row(
            children: [
              AnimatedCounter(
                value: value,
                duration: const Duration(milliseconds: 800),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/$total',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de precisión con anillo de progreso animado.
class _AnimatedAccuracyCard extends StatelessWidget {
  const _AnimatedAccuracyCard({required this.accuracy});
  
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final color = accuracy >= 70 
        ? AppColor.success 
        : (accuracy >= 40 ? Colors.orange : AppColor.error);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: accuracy / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.2)),
                    ),
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCounter(
                  value: accuracy.round(),
                  suffix: '%',
                  duration: const Duration(milliseconds: 800),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Precisión',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.darken(0.1),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.detail, required this.onRetry});

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
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
