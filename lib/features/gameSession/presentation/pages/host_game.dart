import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/constants/answer_option_palette.dart';
import 'package:Trivvy/core/widgets/answer_option_card.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';
import 'package:Trivvy/core/widgets/animated_timer.dart';

import '../../application/dtos/multiplayer_socket_events.dart';
import '../controllers/multiplayer_session_controller.dart';
import 'package:Trivvy/core/utils/countdown_service.dart';
import '../utils/phase_navigator.dart';
import '../widgets/realtime_error_handler.dart';

/// Pantalla del host para dirigir preguntas, mostrar respuestas y avanzar fases.
class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  int _timeRemaining = 0;
  String? _currentSlideId;
  int _lastQuestionSequence = 0;
  int _lastHostGameEndSequence = 0;
  bool _sessionTerminated = false;
  final RealtimeErrorHandler _errorHandler = RealtimeErrorHandler();
  final CountdownService _countdown = CountdownService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWithQuestion();
    _redirectIfGameEnded();
    _checkSessionTermination();
  }

  @override
  void didUpdateWidget(covariant HostGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithQuestion();
    _redirectIfGameEnded();
    _checkSessionTermination();
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }

  /// Sincroniza el slide actual y reinicia contador al cambiar la secuencia.
  void _syncWithQuestion() {
    final controller = context.read<MultiplayerSessionController>();
    final question = controller.currentQuestionDto;
    if (question == null) return;
    if (controller.questionSequence == 0) return;
    if (controller.questionSequence == _lastQuestionSequence) return;

    final slide = question.slide;
    final slideId = slide.id;
    final timeLimit = slide.timeLimitSeconds;
    final issuedAt = controller.questionStartedAt ?? DateTime.now();
    final initialRemaining = _countdown.computeRemaining(
      issuedAt: issuedAt,
      timeLimitSeconds: timeLimit,
    );

    setState(() {
      _lastQuestionSequence = controller.questionSequence;
      _currentSlideId = slideId;
      _timeRemaining = initialRemaining;
    });
    _countdown.start(
      issuedAt: issuedAt,
      timeLimitSeconds: timeLimit,
      onTick: (remaining) {
        if (!mounted) return;
        setState(() => _timeRemaining = remaining);
      },
    );
  }

  /// Redirige al podio cuando el backend emite el cierre de juego del host.
  void _redirectIfGameEnded() {
    final controller = context.read<MultiplayerSessionController>();
    _lastHostGameEndSequence = PhaseNavigator.handleHostGameEnd(
      context: context,
      controller: controller,
      lastSequence: _lastHostGameEndSequence,
    );
  }

  /// Muestra aviso y sale si el servidor cierra la sesión de forma remota.
  void _checkSessionTermination() {
    final controller = context.read<MultiplayerSessionController>();
    _sessionTerminated = PhaseNavigator.handleSessionTermination(
      context: context,
      controller: controller,
      alreadyTerminated: _sessionTerminated,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combina estado de pregunta/resultados para mostrar CTA y tablero.
    final controller = context.watch<MultiplayerSessionController>();
    final question = controller.currentQuestionDto;
    final slide = question?.slide;
    final hostResults = controller.hostResultsDto;
    final showingResults =
      controller.phase == SessionPhase.results && hostResults != null;
    final quizTitle = controller.quizTitle ?? 'Trivvy!';
    final headerSubtitle = _buildHeaderSubtitle(slide, hostResults);
    final options = _buildOptionsFromDto(slide, hostResults);
    final leaderboardEntries = hostResults?.leaderboard ??
      const <LeaderboardEntry>[];

    final primaryCta = _buildPrimaryCta(controller, slide != null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _errorHandler.handle(
        context: context,
        controller: controller,
        onExit: _exitToHome,
      );
    });

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
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quizTitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                headerSubtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (controller.lastError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  controller.lastError!,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            FilledButton.tonal(
                              onPressed: primaryCta.action,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColor.primary,
                              ),
                              child: Text(primaryCta.label),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: controller.emitHostEndSession,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Terminar juego'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (slide == null)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Esperando la siguiente pregunta...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width < 520 ? 1 : 2;
                            final childAspectRatio = width < 520 ? 4.2 : 2.5;
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _QuestionCard(
                                    key: ValueKey<String?>(_currentSlideId),
                                    text: slide.questionText,
                                  ),
                                  const SizedBox(height: 14),
                                  if (showingResults) ...[
                                    StaggeredFadeSlide(
                                      index: 0,
                                      child: _StatsCard(options: options),
                                    ),
                                    const SizedBox(height: 12),
                                    StaggeredFadeSlide(
                                      index: 1,
                                      child: _ResultsLeaderboard(entries: leaderboardEntries),
                                    ),
                                    const SizedBox(height: 12),
                                  ] else ...[
                                    _MediaAndTimerBlock(
                                      time: _timeRemaining,
                                      imageUrl: slide.imageUrl,
                                    ),
                                    const SizedBox(height: 12),
                                    _SubmissionsCounterCard(
                                      submissions: controller.hostAnswerSubmissions ?? 0,
                                      totalPlayers: controller.lobbyPlayers.length,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                    itemCount: options.length,
                                    itemBuilder: (_, index) {
                                      final tile = _AnswerTile(
                                        option: options[index],
                                        showResults: showingResults,
                                      );
                                      // Cuando se muestran resultados, anima cada mosaico
                                      if (showingResults) {
                                        return StaggeredFadeSlide(
                                          index: 2 + index, // offset by stats + leaderboard
                                          child: tile,
                                        );
                                      }
                                      return tile;
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Determina la acción principal (CTA) según la fase actual.
  _PrimaryCta _buildPrimaryCta(
    MultiplayerSessionController controller,
    bool canAdvance,
  ) {
    VoidCallback? action;
    String label = 'Esperando';
    switch (controller.phase) {
      case SessionPhase.question:
        label = 'Mostrar resultados';
        action = canAdvance ? controller.emitHostNextPhase : null;
        break;
      case SessionPhase.results:
        label = 'Siguiente pregunta';
        action = controller.emitHostNextPhase;
        break;
      case SessionPhase.end:
        label = 'Ver podio';
        action = controller.emitHostNextPhase;
        break;
      case SessionPhase.lobby:
        label = 'Esperando jugadores';
        action = null;
        break;
    }
    return _PrimaryCta(
      label: action == null ? 'Esperando' : label,
      action: action,
    );
  }

  void _exitToHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// Tarjeta central con el enunciado de la pregunta.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColor.primary,
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Muestra imagen opcional y contador mientras los jugadores responden.
class _MediaAndTimerBlock extends StatelessWidget {
  const _MediaAndTimerBlock({required this.time, this.imageUrl});

  final int time;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 150,
              color: Colors.white.withValues(alpha: 0.12),
              child: imageUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedTimer(timeRemaining: time),
              const SizedBox(height: 6),
              const Text(
                'Respondiendo...',
                style: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Visualiza distribución de respuestas y marca las correctas.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.options});

  final List<_HostOption> options;

  @override
  Widget build(BuildContext context) {
    final maxVotes = options.fold<int>(1, (prev, option) {
      return option.responses > prev ? option.responses : prev;
    });
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final heightFactor = maxVotes == 0
              ? 0.15
              : (option.responses / maxVotes).clamp(0.15, 1.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + index * 100),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: option.isCorrect ? 1.0 : 0.0),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.5 + 0.5 * value,
                    child: child,
                  ),
                ),
                child: option.isCorrect
                    ? const Icon(Icons.check_circle, color: AppColor.success)
                    : const SizedBox(height: 24),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 600 + index * 100),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: heightFactor),
                builder: (context, animatedHeight, _) => Container(
                  width: 50,
                  height: 160 * animatedHeight,
                  decoration: BoxDecoration(
                    color: option.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedCounter(
                value: option.responses,
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Opción individual del host, con contador de respuestas cuando hay resultados.
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.option, required this.showResults});

  final _HostOption option;
  final bool showResults;

  @override
  Widget build(BuildContext context) {
    final background = showResults && !option.isCorrect
        ? option.color.withValues(alpha: 0.35)
        : option.color;
    return AnswerOptionCard(
      layout: Axis.horizontal,
      text: option.label,
      icon: option.icon,
      color: background,
      trailing: showResults
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.isCorrect)
                  const Icon(Icons.check, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${option.responses}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}

/// Lista ordenada de jugadores (por puntuación) bajo el gráfico de distribución.
class _ResultsLeaderboard extends StatelessWidget {
  const _ResultsLeaderboard({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final sorted = List<LeaderboardEntry>.from(entries)
      ..sort((a, b) {
        final scoreDiff = b.score.compareTo(a.score);
        if (scoreDiff != 0) return scoreDiff;
        // Tie-breaker: lower rank first when present.
        if (a.rank != 0 && b.rank != 0) {
          final rankDiff = a.rank.compareTo(b.rank);
          if (rankDiff != 0) return rankDiff;
        }
        return a.nickname.compareTo(b.nickname);
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jugadores en orden',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < sorted.length; i++)
            StaggeredFadeSlide(
              index: i,
              staggerDelay: const Duration(milliseconds: 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 400 + i * 50),
                      curve: Curves.easeOutBack,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${sorted[i].rank == 0 ? i + 1 : sorted[i].rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sorted[i].nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedCounter(
                      value: sorted[i].score,
                      suffix: ' pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryCta {
  const _PrimaryCta({required this.label, this.action});

  final String label;
  final VoidCallback? action;
}

class _HostOption {
  const _HostOption({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
    required this.isCorrect,
    required this.responses,
  });

  final String id;
  final String label;
  final Color color;
  final IconData icon;
  final bool isCorrect;
  final int responses;
}

/// Construye subtítulo de cabecera con posición de pregunta.
String _buildHeaderSubtitle(SlideData? slide, HostResultsEvent? hostResults) {
  if (slide == null) return 'Esperando pregunta';
  final totalSlides = hostResults?.progress.total;
  final current = slide.position + 1;
  if (totalSlides != null && totalSlides > 0) {
    return 'Pregunta $current de $totalSlides';
  }
  return 'Pregunta $current';
}

/// Adapta opciones del slide + métricas de resultados para la UI del host.
List<_HostOption> _buildOptionsFromDto(
  SlideData? slide,
  HostResultsEvent? hostResults,
) {
  if (slide == null) return const <_HostOption>[];
  final responseCounts = _extractResponseCountsFromDto(hostResults);
  final correctAnswerIds = _extractCorrectAnswerIdsFromDto(hostResults);

  return List<_HostOption>.generate(slide.options.length, (index) {
    final option = slide.options[index];
    final optionId = option.id;
    final responses =
        responseCounts[optionId] ??
        responseCounts['$index'] ??
        responseCounts['${index + 1}'] ??
        0;

    final inferredCorrect = correctAnswerIds.isNotEmpty &&
        (correctAnswerIds.contains(optionId) ||
            correctAnswerIds.contains('$index') ||
            correctAnswerIds.contains('${index + 1}'));

    return _HostOption(
      id: optionId,
      label: option.text,
      color: answerOptionColors[index % answerOptionColors.length],
      icon: answerOptionIcons[index % answerOptionIcons.length],
      isCorrect: inferredCorrect,
      responses: responses,
    );
  });
}

/// Extrae identificadores de respuestas correctas del DTO.
Set<String> _extractCorrectAnswerIdsFromDto(HostResultsEvent? hostResults) {
  if (hostResults == null) return const <String>{};
  return hostResults.correctAnswerIds.toSet();
}

/// Widget que muestra el contador de respuestas en tiempo real durante la pregunta.
class _SubmissionsCounterCard extends StatelessWidget {
  const _SubmissionsCounterCard({
    required this.submissions,
    required this.totalPlayers,
  });

  final int submissions;
  final int totalPlayers;

  @override
  Widget build(BuildContext context) {
    final remaining = (totalPlayers - submissions).clamp(0, totalPlayers);
    final percentage =
        totalPlayers > 0 ? (submissions / totalPlayers * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Respuestas enviadas',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$submissions/$totalPlayers',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalPlayers > 0 ? submissions / totalPlayers : 0,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                submissions == totalPlayers ? Colors.green : AppColor.secundary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (remaining > 0)
            Text(
              'Esperando $remaining ${remaining == 1 ? 'respuesta' : 'respuestas'} ($percentage%)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            )
          else
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text(
                  'Todas las respuestas recibidas',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Mapea opción -> número de respuestas desde las estadísticas.
Map<String, int> _extractResponseCountsFromDto(HostResultsEvent? hostResults) {
  if (hostResults == null) return const <String, int>{};
  return Map<String, int>.from(hostResults.stats.distribution);
}
