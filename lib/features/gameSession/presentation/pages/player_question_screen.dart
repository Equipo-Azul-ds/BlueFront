import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Pantalla de pregunta para el jugador (envío de respuestas y temporizador).
class PlayerQuestionScreen extends StatefulWidget {
  const PlayerQuestionScreen({super.key});

  @override
  State<PlayerQuestionScreen> createState() => _PlayerQuestionScreenState();
}

class _PlayerQuestionScreenState extends State<PlayerQuestionScreen> {
  int _timeRemaining = 0;
  String? _currentSlideId;
  int _lastQuestionSequence = 0;
  int _lastPlayerGameEndSequence = 0;
  int _lastResultsSequence = 0;
  bool _sessionTerminated = false;
  final Set<String> _selectedAnswerIds = <String>{};
  bool _answerSubmitted = false;
  bool _currentIsMultiSelect = false;
  int? _currentMaxSelections;
  bool _answerConfirmed = false;
  final RealtimeErrorHandler _errorHandler = RealtimeErrorHandler();
  final CountdownService _countdown = CountdownService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWithController();
    _checkFinalResults();
    _checkQuestionResults();
    _checkSessionTermination();
    _checkRealtimeErrors();
    _checkAnswerConfirmation();
  }

  @override
  void didUpdateWidget(covariant PlayerQuestionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithController();
    _checkFinalResults();
    _checkQuestionResults();
    _checkSessionTermination();
    _checkRealtimeErrors();
    _checkAnswerConfirmation();
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }

  /// Resetea estado local al recibir una nueva pregunta del socket.
  void _syncWithController() {
    
    final controller = context.read<MultiplayerSessionController>();
    final question = controller.currentQuestionDto;
    if (question == null) return;
    if (_lastQuestionSequence == controller.questionSequence) return;

    final slide = question.slide;

    _lastQuestionSequence = controller.questionSequence;
    _currentSlideId = slide.id;
    _selectedAnswerIds.clear();
    _answerSubmitted = question.hasAnswered == true;
    _answerConfirmed = false;

    _currentIsMultiSelect = _resolveIsMultiSelect(slide);
    _currentMaxSelections = slide.maxSelections;

    final timeLimit = slide.timeLimitSeconds;
    final issuedAt = controller.questionStartedAt ?? DateTime.now();
    final remaining = _countdown.computeRemaining(
      issuedAt: issuedAt,
      timeLimitSeconds: timeLimit,
    );
    setState(() => _timeRemaining = remaining);
    _countdown.start(
      issuedAt: issuedAt,
      timeLimitSeconds: timeLimit,
      onTick: (seconds) {
        if (!mounted) return;
        setState(() => _timeRemaining = seconds);
      },
      onElapsed: () {
        if (_answerSubmitted) return;
        // Evitar enviar un arreglo vacío (el backend puede rechazarlo).
        // Si el usuario ya seleccionó opciones, enviarlas automáticamente;
        // si no hay selecciones, marcar como expirado localmente y no emitir.
        if (_selectedAnswerIds.isEmpty) {
          if (!mounted) return;
          setState(() => _answerSubmitted = true);
          _countdown.cancel();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tiempo agotado — no se envió ninguna respuesta'),
            duration: Duration(seconds: 2),
          ));
          return;
        }
        _submitAnswers(_selectedAnswerIds.toList());
      },
    );
  }

  /// Fallback para strings antiguos; la app ya trae slide.isMultiSelect resuelto.
  bool _isMultiSelect(String slideType) {
    final normalized = slideType.toLowerCase();
    return normalized.contains('multi') || normalized.contains('checkbox');
  }

  /// Determina si la pregunta admite selección múltiple.
  bool _resolveIsMultiSelect(SlideData slide) {
    if (slide.isMultiSelect) return true;
    return _isMultiSelect(slide.slideType);
  }

  /// Redirige al resumen final cuando llega el evento de fin de juego.
  void _checkFinalResults() {
    final controller = context.read<MultiplayerSessionController>();
    _lastPlayerGameEndSequence = PhaseNavigator.handlePlayerFinalResults(
      context: context,
      controller: controller,
      lastSequence: _lastPlayerGameEndSequence,
    );
  }

  /// Salta a resultados de pregunta cuando llega player_results.
  void _checkQuestionResults() {
    final controller = context.read<MultiplayerSessionController>();
    _lastResultsSequence = PhaseNavigator.handlePlayerQuestionResults(
      context: context,
      controller: controller,
      lastSequence: _lastResultsSequence,
    );
  }

  /// Sale al inicio si el host cierra la sesión o se desconecta.
  void _checkSessionTermination() {
    final controller = context.read<MultiplayerSessionController>();
    _sessionTerminated = PhaseNavigator.handleSessionTermination(
      context: context,
      controller: controller,
      alreadyTerminated: _sessionTerminated,
    );
  }

  /// Muestra alertas para errores de conexión/sincronización del socket.
  void _checkRealtimeErrors() {
    final controller = context.read<MultiplayerSessionController>();
    _errorHandler.handle(
      context: context,
      controller: controller,
      onExit: _exitToHome,
    );
  }

  /// Monitorea confirmación del servidor de que la respuesta fue recibida.
  void _checkAnswerConfirmation() {
    final controller = context.read<MultiplayerSessionController>();
    final confirmation = controller.playerAnswerConfirmationDto;
    if (confirmation != null && !_answerConfirmed && _answerSubmitted) {
      _answerConfirmed = true;
      if (mounted) {
        setState(() {});
        // Activar retroalimentación háptica de éxito
        HapticFeedback.lightImpact();
      }
    }
  }

  void _exitToHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Maneja selección única o múltiple según configuración del slide.
  void _handleOptionTap(String answerId) {
    
    if (_answerSubmitted) return;

    if (_currentIsMultiSelect) {
      setState(() {
        if (_selectedAnswerIds.contains(answerId)) {
          _selectedAnswerIds.remove(answerId);
          return;
        }
        final maxSelections = _currentMaxSelections;
        if (maxSelections != null && maxSelections > 0) {
          if (_selectedAnswerIds.length >= maxSelections) {
            // Mostrar aviso de que se alcanzó el máximo de selecciones
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Máximo $maxSelections opciones permitidas'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
        _selectedAnswerIds.add(answerId);
      });
      return;
    }

    _submitAnswers(<String>[answerId]);
  }

  /// Envía la respuesta con el tiempo transcurrido.
  Future<void> _submitAnswers(List<String> answerIds) async {
    if (_answerSubmitted) return;
    final slideId = _currentSlideId;
    if (slideId == null) return;

    final controller = context.read<MultiplayerSessionController>();
    setState(() => _answerSubmitted = true);
    _countdown.cancel();
    HapticFeedback.mediumImpact();
    final issuedAt = controller.questionStartedAt ?? DateTime.now();
    final elapsedMs = DateTime.now().difference(issuedAt).inMilliseconds;

    try {
      await controller.submitPlayerAnswer(
        questionId: slideId,
        answerIds: answerIds,
        timeElapsedMs: elapsedMs,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
        content: Text('Respuesta enviada... esperando confirmación'),
        duration: Duration(seconds: 2),
      ));
    } catch (error) {
      if (!mounted) return;
      setState(() => _answerSubmitted = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar respuesta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MultiplayerSessionController>();
    final question = controller.currentQuestionDto;

    if (question == null) {
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
            child: Text(
              'Esperando a que inicie la siguiente pregunta...',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final slide = question.slide;
    final options = slide.options;
    final isMultiSelect = _resolveIsMultiSelect(slide);
    final maxSelections = slide.maxSelections ?? _currentMaxSelections;
    final quizTitle = controller.quizTitle ?? 'Trivvy!';
    final questionIndex = question.slide.position;
    final currentSequence = controller.questionSequence;
    final current = currentSequence > 0 ? currentSequence : (questionIndex + 1);
    final questionLabel = 'Pregunta $current';

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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    quizTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    questionLabel,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (isMultiSelect) ...[
                    const SizedBox(height: 8),
                    Text(
                      maxSelections != null && maxSelections > 0
                          ? 'Selecciona hasta $maxSelections opciones'
                          : 'Selecciona una o más opciones',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AnimatedTimer(timeRemaining: _timeRemaining),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            slide.questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColor.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (slide.imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  slide.imageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    height: 180,
                                    color: Colors.black.withValues(alpha: 0.1),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width < 420 ? 1 : 2;
                        final childAspectRatio = width < 420 ? 3.4 : 1.2;
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final answerId = option.id;
                            return StaggeredFadeSlide(
                              index: index,
                              duration: const Duration(milliseconds: 350),
                              staggerDelay: const Duration(milliseconds: 60),
                              child: AnswerOptionCard(
                                text: option.text,
                                icon: answerOptionIcons[
                                    index % answerOptionIcons.length],
                                color: answerOptionColors[
                                    index % answerOptionColors.length],
                                selected: _selectedAnswerIds.contains(answerId),
                                disabled: _answerSubmitted,
                                onTap: () => _handleOptionTap(answerId),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (isMultiSelect && !_answerSubmitted)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                        left: 20,
                        right: 20,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedAnswerIds.isEmpty
                              ? null
                              : () =>
                                    _submitAnswers(_selectedAnswerIds.toList()),
                          icon: const Icon(Icons.send_rounded),
                          label: Text(
                            maxSelections != null && maxSelections > 0
                                ? 'Enviar (${_selectedAnswerIds.length}/$maxSelections)'
                                : 'Enviar (${_selectedAnswerIds.length})',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.secundary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_answerSubmitted)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 24,
                        left: 20,
                        right: 20,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: _answerConfirmed
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _answerConfirmed ? Colors.green[300]! : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _answerConfirmed ? Icons.check_circle : Icons.hourglass_bottom,
                              color: _answerConfirmed ? Colors.green[300] : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _answerConfirmed
                                    ? 'Respuesta confirmada ✓'
                                    : 'Respuesta enviada. Esperando confirmación...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _answerConfirmed ? Colors.green[300] : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
