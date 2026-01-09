import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';

import '../controllers/multiplayer_session_controller.dart';
import 'player_question_screen.dart';
import 'player_results_screen.dart';

/// Paleta de colores para el resultado de pregunta.
class _ResultPalette {
  static const Color successBg = Color(0xFF4ADE80);
  static const Color successText = Color(0xFF166534);
  static const Color errorBg = Color(0xFFF87171);
  static const Color errorText = Color(0xFF991B1B);
  static const Color cardBg = Color(0xFFFFFBEB);
  static const Color streakOrange = Color(0xFFF97316);
  static const Color rankPurple = Color(0xFF8B5CF6);
  static const Color pointsBlue = Color(0xFF3B82F6);
}

/// Muestra el resultado de una pregunta para el jugador y espera la siguiente.
class PlayerQuestionResultsScreen extends StatefulWidget {
  const PlayerQuestionResultsScreen({
    super.key,
    required this.sequenceNumber,
  });

  /// Secuencia de pregunta usada para saber cuándo llega la siguiente.
  final int sequenceNumber;

  @override
  State<PlayerQuestionResultsScreen> createState() => _PlayerQuestionResultsScreenState();
}

class _PlayerQuestionResultsScreenState extends State<PlayerQuestionResultsScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  bool _sessionTerminated = false;
  bool _hapticTriggered = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Trigger haptic feedback when results are shown
  void _triggerResultsHaptic(bool isCorrect) {
    if (_hapticTriggered) return;
    _hapticTriggered = true;
    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MultiplayerSessionController>();
    final result = controller.playerResultsDto;

    _checkSessionTermination(controller);

    // Si llega el fin de juego, pasamos al resumen final.
    if (!_navigated && controller.playerGameEndDto != null) {
      _navigate((_) => const PlayerResultsScreen());
    }

    // Si el host lanzó la siguiente pregunta, volvemos al flujo de preguntas.
    if (!_navigated && controller.phase == SessionPhase.question &&
        controller.questionSequence > widget.sequenceNumber) {
      _navigate((_) => const PlayerQuestionScreen());
    }

    if (result == null) {
      return _loadingScaffold();
    }

    // Trigger haptic feedback once when results are shown
    _triggerResultsHaptic(result.isCorrect);

    final isCorrect = result.isCorrect;
    final points = result.pointsEarned;
    final totalScore = result.totalScore;
    final rank = result.rank;
    final previousRank = result.previousRank;
    final streak = result.streak;
    final progress = result.progress;
    final questionLabel = progress.total > 0
        ? 'Pregunta ${progress.current} de ${progress.total}'
        : 'Pregunta actual';

    final rankDelta = (rank > 0 && previousRank > 0) ? previousRank - rank : 0;
    final rankLabel = rank > 0 ? 'Posición: $rank' : 'Posición no disponible';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.secundary, AppColor.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        questionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _ResultBadge(isCorrect: isCorrect, points: points),
                      ),
                    ),
                    const SizedBox(height: 20),
                    StaggeredFadeSlide(
                      index: 0,
                      duration: const Duration(milliseconds: 400),
                      staggerDelay: const Duration(milliseconds: 100),
                      child: _StatCard(
                        label: 'Puntos acumulados',
                        value: totalScore,
                        icon: Icons.stacked_line_chart,
                        iconColor: _ResultPalette.pointsBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggeredFadeSlide(
                      index: 1,
                      duration: const Duration(milliseconds: 400),
                      staggerDelay: const Duration(milliseconds: 100),
                      child: _StatCard(
                        label: rankLabel,
                        valueText: rankDelta == 0
                            ? 'Sin cambio'
                            : (rankDelta > 0
                                ? 'Subiste $rankDelta posiciones'
                                : 'Bajaste ${rankDelta.abs()} posiciones'),
                        icon: Icons.emoji_events_outlined,
                        iconColor: _ResultPalette.rankPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggeredFadeSlide(
                      index: 2,
                      duration: const Duration(milliseconds: 400),
                      staggerDelay: const Duration(milliseconds: 100),
                      child: _StatCard(
                        label: 'Racha',
                        value: streak,
                        valueText: streak > 0 ? '🔥 $streak en racha' : 'Sin racha',
                        icon: Icons.local_fire_department_outlined,
                        iconColor: _ResultPalette.streakOrange,
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const _WaitingIndicator(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Navega a la pantalla indicada evitando dobles redirecciones.
  void _navigate(WidgetBuilder builder) {
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: builder));
    });
  }

  /// Placeholder mientras se espera el payload de resultados.
  Widget _loadingScaffold() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.secundary, AppColor.primary],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }

  /// Sale al inicio si la sesión se cerró o el host abandonó.
  void _checkSessionTermination(MultiplayerSessionController controller) {
    if (_sessionTerminated) return;
    final closed = controller.sessionClosedDto;
    final hostLeft = controller.hostLeftDto;
    if (closed == null && hostLeft == null) return;
    _sessionTerminated = true;
    final message = closed?.message ?? hostLeft?.message ?? 'La sesión ha sido cerrada.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.isCorrect, required this.points});

  final bool isCorrect;
  final int points;

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect ? _ResultPalette.successBg : _ResultPalette.errorBg;
    final textColor = isCorrect ? _ResultPalette.successText : _ResultPalette.errorText;
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final text = isCorrect ? '¡Correcto!' : 'Respuesta incorrecta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 56),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: Colors.black87),
                AnimatedCounter(
                  value: points,
                  duration: const Duration(milliseconds: 800),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  suffix: ' pts',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    this.value,
    this.valueText,
    required this.icon,
    this.iconColor,
  });

  final String label;
  final int? value;
  final String? valueText;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final displayColor = iconColor ?? Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: displayColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (value != null)
                  AnimatedCounter(
                    value: value!,
                    duration: const Duration(milliseconds: 600),
                    suffix: ' pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Text(
                    valueText ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

/// Indicador de espera pulsante.
class _WaitingIndicator extends StatefulWidget {
  const _WaitingIndicator();

  @override
  State<_WaitingIndicator> createState() => _WaitingIndicatorState();
}

class _WaitingIndicatorState extends State<_WaitingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Esperando siguiente pregunta...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
