import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/constants/answer_option_palette.dart';
import 'package:Trivvy/core/utils/countdown_service.dart';
import 'package:Trivvy/core/widgets/answer_option_card.dart';
import 'package:Trivvy/core/widgets/standard_dialogs.dart';
import 'package:Trivvy/core/widgets/game_ui_kit.dart';

import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';
import '../blocs/single_player_challenge_bloc.dart';
import 'single_player_challenge_results.dart';

// Pantalla principal del desafío single-player.
// Responsable de mostrar la pregunta actual, temporizador, opciones y el
// overlay de revisión (reveal) cuando llega la evaluación de la respuesta.
class SinglePlayerChallengeScreen extends StatefulWidget {
  final String quizId;
  final SinglePlayerGame? initialGame;
  final SlideDTO? initialSlide;

  const SinglePlayerChallengeScreen({
    super.key,
    required this.quizId,
    this.initialGame,
    this.initialSlide,
  });

  @override
  State<SinglePlayerChallengeScreen> createState() =>
      _SinglePlayerChallengeScreenState();
}

class _SinglePlayerChallengeScreenState
    extends State<SinglePlayerChallengeScreen>
    with SingleTickerProviderStateMixin {
  late SinglePlayerChallengeBloc bloc;
  bool _blocInitialized = false;

  final CountdownService _countdown = CountdownService();
  DateTime? _countdownIssuedAt;
  final Set<int> _selectedIndexes = <int>{};
  bool _answerRevealed = false;
  bool _hasEvaluation = false;
  int _timeRemaining = 0;
  SlideDTO? _displayedSlide;
  SlideDTO? _pendingSlide;
  late final AnimationController _reviewController;
  static const int _reviewDurationMs = 2000;
  EvaluatedAnswer? _displayedEvaluated;

  int? _serverIndexForButton(SlideDTO slide, int buttonIndex) {
    if (buttonIndex < 0 || buttonIndex >= slide.options.length) {
      return null;
    }
    return slide.options[buttonIndex].index;
  }

  int? _buttonIndexForServer(List<SlideOptionDTO> options, int? serverIndex) {
    if (serverIndex == null) {
      return null;
    }
    for (var i = 0; i < options.length; i++) {
      if (options[i].index == serverIndex) {
        return i;
      }
    }
    return null;
  }

  @override
  // didChangeDependencies: iniciamos el BLoC y arrancamos/reamos el intento
  // justo después de que el widget esté montado, para evitar llamadas en
  // el constructor.
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_blocInitialized) {
      bloc = Provider.of<SinglePlayerChallengeBloc>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final SinglePlayerGame? resumeGame = widget.initialGame;
        final SlideDTO? resumeSlide = widget.initialSlide;
        final Future<void> launchFuture = resumeGame != null
            ? bloc.hydrateExistingGame(resumeGame, nextSlide: resumeSlide)
            : bloc.startGame(widget.quizId);

        launchFuture.catchError((error) {
          if (!mounted) return;
          showBlockingErrorDialog(
            context: context,
            title: 'No se pudo iniciar el juego',
            message: '$error',
            onExit: () => Navigator.of(context).pop(),
          );
        });
      });

      bloc.addListener(_onBlocChanged);

      _blocInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _reviewController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: _reviewDurationMs),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _applyPendingOrAdvance();
          }
        });
  }

  // _onBlocChanged: callback llamado cuando el BLoC notifica cambios.
  // Actualiza la slide mostrada o encola la próxima slide si estamos en
  // la ventana de revisión (answer reveal).
  void _onBlocChanged() {
    final slide = bloc.currentSlide;
    if (!mounted) return;

    if (_answerRevealed) {
      _pendingSlide = slide;
      return;
    }

    _cancelTimers();
    setState(() {
      _selectedIndexes.clear();
      _answerRevealed = false;
      _hasEvaluation = false;
      _displayedSlide = slide;
    });

    if (_displayedSlide != null) {
      _startCountdown(_displayedSlide!.timeLimitSeconds);
    }
  }

  // _startCountdown: inicia un Timer que decrementa el contador cada
  // segundo y llama a _onTimeExpired cuando llega a 0.
  void _startCountdown(int seconds) {
    _countdown.cancel();
    final issuedAt = DateTime.now();
    _countdownIssuedAt = issuedAt;
    final initial = _countdown.computeRemaining(
      issuedAt: issuedAt,
      timeLimitSeconds: seconds,
    );
    setState(() {
      _timeRemaining = initial;
    });
    _countdown.start(
      issuedAt: issuedAt,
      timeLimitSeconds: seconds,
      onTick: (remaining) {
        if (!mounted) return;
        setState(() => _timeRemaining = remaining);
      },
      onElapsed: _onTimeExpired,
    );
  }

  // _onTimeExpired: tiempo agotado -> enviamos null como respuesta.
  void _onTimeExpired() {
    if (_answerRevealed) return;
    if (_selectedIndexes.isEmpty) {
      _submitAnswer(null);
      return;
    }
    _submitAnswer(_selectedIndexes.toList()..sort());
  }

  void _cancelTimers() {
    _countdown.cancel();
    if (_reviewController.isAnimating) {
      _reviewController.stop();
      _reviewController.reset();
    }
  }

  // _submitAnswer: construye PlayerAnswer con el tiempo usado y llama
  // al BLoC. Muestra la UI de revisión y arranca el AnimationController
  // que mostrará el progreso circular durante el periodo de review.
  Future<void> _submitAnswer(List<int>? selectedIdxs) async {
    final currentDisplayed = _displayedSlide ?? bloc.currentSlide;
    if (bloc.currentGame == null || currentDisplayed == null) return;

    if (_answerRevealed) return;

    _countdown.cancel();

    final totalSeconds = currentDisplayed.timeLimitSeconds;
    final timeUsedSeconds = totalSeconds - _timeRemaining;
    final int rawElapsedMs = _countdownIssuedAt != null
      ? DateTime.now().difference(_countdownIssuedAt!).inMilliseconds
      : (timeUsedSeconds * 1000).round();
    final int timeUsedMs =
      rawElapsedMs.clamp(0, totalSeconds * 1000).toInt();
    final serverAnswerIndexes = selectedIdxs == null
        ? null
        : selectedIdxs
              .map((idx) => _serverIndexForButton(currentDisplayed, idx))
              .whereType<int>()
              .toList();
    final normalizedServerIndexes =
        serverAnswerIndexes == null || serverAnswerIndexes.isEmpty
        ? null
        : (serverAnswerIndexes..sort());

    final playerAnswer = PlayerAnswer(
      slideId: currentDisplayed.slideId,
      answerIndex: normalizedServerIndexes,
      timeUsedMs: timeUsedMs,
    );

    setState(() {
      _selectedIndexes
        ..clear()
        ..addAll(selectedIdxs ?? const <int>[]);
      _answerRevealed = true;
      _hasEvaluation = false;
      _displayedEvaluated = null;
    });

    await bloc.submitAnswer(playerAnswer);
    if (!mounted) return;

    setState(() {
      _displayedEvaluated = bloc.lastResult?.evaluatedAnswer;
      _hasEvaluation = true;
    });

    if (_reviewController.isAnimating) {
      _reviewController.stop();
    }
    _reviewController.reset();
    _reviewController.forward();
  }

  bool _supportsMultipleAnswers(SlideDTO slide) {
    final normalized = slide.questionType.trim().toLowerCase();
    const multiEnums = <String>{
      'multi_select',
      'multiple_select',
      'multiple_choice',
      'multiple_answer',
      'multiple_answers',
      'multi_answer',
      'multi_answers',
      'checkbox',
    };
    if (multiEnums.contains(normalized)) return true;
    return normalized.contains('multi') ||
        normalized.contains('multiple') ||
        normalized.contains('checkbox');
  }

  // _applyPendingOrAdvance: llamado cuando finaliza la ventana de
  // revisión. Si se ha encolado una slide la aplicamos; si el intento
  // terminó, navegamos a la pantalla de resultados; si no, tomamos la
  // siguiente slide desde el BLoC.
  void _applyPendingOrAdvance() {
    final currentGame = bloc.currentGame;

    if (_pendingSlide != null) {
      setState(() {
        _displayedSlide = _pendingSlide;
        _pendingSlide = null;
        _selectedIndexes.clear();
        _answerRevealed = false;
        _hasEvaluation = false;
      });
      _startCountdown(_displayedSlide!.timeLimitSeconds);
      return;
    }

    final bool finished =
        currentGame == null ||
        currentGame.gameProgress.state == GameProgressStatus.COMPLETED ||
        bloc.currentSlide == null;

    if (finished && mounted && currentGame != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SinglePlayerChallengeResultsScreen(
            gameId: currentGame.gameId,
            initialSummaryGame: currentGame,
          ),
        ),
      );
      return;
    }

    setState(() {
      _displayedSlide = bloc.currentSlide;
      _selectedIndexes.clear();
      _answerRevealed = false;
      _hasEvaluation = false;
    });

    if (_displayedSlide != null) {
      _startCountdown(_displayedSlide!.timeLimitSeconds);
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    bloc.removeListener(_onBlocChanged);
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SinglePlayerChallengeBloc>.value(
      value: bloc,
      child: Consumer<SinglePlayerChallengeBloc>(
        builder: (context, b, _) {
          if ((b.isLoading && !_answerRevealed) ||
              (b.currentSlide == null && _displayedSlide == null)) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final slide = _displayedSlide ?? b.currentSlide!;
          final answers = slide.options;
          final qText = slide.questionText;
          final mediaUrl = slide.mediaUrl;
          final bool isMultiSelect = _supportsMultipleAnswers(slide);

          // Construye las opciones
          Widget buildOption(int idx, double optionWidth) {
            final ansText = answers[idx].text ?? '';
            final baseColor = answerOptionColors[idx % answerOptionColors.length];
            final icon = answerOptionIcons[idx % answerOptionIcons.length];

            final bool isSelected = _selectedIndexes.contains(idx);
            final bool reveal = _answerRevealed;
            final int? correctIdx = _buttonIndexForServer(
              answers,
              b.lastCorrectIndex,
            );
            final bool isCorrect =
                reveal && correctIdx != null && correctIdx == idx;

            Color backgroundColor = baseColor;
            IconData? indicatorIcon;
            if (reveal) {
              backgroundColor = isCorrect
                  ? AppColor.success
                  : (isSelected ? AppColor.error : baseColor);
              if (isCorrect) {
                indicatorIcon = Icons.check;
              } else if (isSelected) {
                indicatorIcon = Icons.close;
              }
            }

            return SizedBox(
              width: optionWidth,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnswerOptionCard(
                  layout: Axis.horizontal,
                  text: ansText,
                  icon: icon,
                  color: backgroundColor,
                  selected: isSelected,
                  disabled: reveal,
                  trailing:
                      indicatorIcon != null ? Icon(indicatorIcon, size: 22) : null,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 14,
                  ),
                  onTap: reveal
                      ? null
                      : () {
                          if (isMultiSelect) {
                            setState(() {
                              if (isSelected) {
                                _selectedIndexes.remove(idx);
                              } else {
                                _selectedIndexes.add(idx);
                              }
                            });
                            return;
                          }

                          _countdown.cancel();
                          _submitAnswer([idx]);
                        },
                ),
              ),
            );
          }

          Widget buildMedia(String mediaPath) {
            Widget buildFallback() {
              return Container(
                height: 160,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image)),
              );
            }

            final uri = Uri.tryParse(mediaPath);
            final bool isRemote =
                uri != null &&
                uri.hasScheme &&
                (uri.scheme == 'http' || uri.scheme == 'https');

            final image = isRemote
                ? Image.network(
                    mediaPath,
                    height: 360,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => buildFallback(),
                  )
                : Image.asset(
                    mediaPath,
                    height: 360,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => buildFallback(),
                  );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image,
              ),
            );
          }

          // Construye el Area de los bloques para preguntas
          Widget buildQuestionArea() {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SurfaceCard(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Text(
                  qText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }

          // Barra para mostrar resultados
          Widget buildReviewBar() {
            final bool isUnanswered = _selectedIndexes.isEmpty;
            final bool isCorrect =
                !isUnanswered &&
                (_displayedEvaluated?.wasCorrect ??
                    (b.lastResult?.evaluatedAnswer.wasCorrect ?? false));
            final int pointsEarned = isCorrect
                ? (_displayedEvaluated?.pointsEarned ??
                      (b.lastResult?.evaluatedAnswer.pointsEarned ?? 0))
                : 0;
            return Container(
              width: double.infinity,
              color: isCorrect ? AppColor.success : AppColor.error,
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      isUnanswered
                          ? 'Tiempo agotado'
                          : (isCorrect ? 'Correcto' : 'Incorrecto'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isUnanswered)
                      const Text(
                        'Sin responder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (isCorrect)
                      Text(
                        '+$pointsEarned',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          final bool canShowReviewUi = _answerRevealed && _hasEvaluation;
          final bool canSubmitMulti =
              isMultiSelect && !_answerRevealed && _selectedIndexes.isNotEmpty;

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColor.secundary, AppColor.primary],
                ),
              ),
              child: Column(
                children: [
                  if (canShowReviewUi) buildReviewBar(),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SafeArea(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.only(
                                      top: _answerRevealed ? 0 : 20,
                                      left: 12,
                                      right: 12,
                                      bottom: isMultiSelect ? 92 : 24,
                                    ),
                                    child: Column(
                                      key: ValueKey<String>(slide.slideId),
                                      children: [
                                        if (!_answerRevealed)
                                          Container(
                                            width: 60,
                                            height: 60,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white54,
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              '$_timeRemaining',
                                              style: const TextStyle(
                                                color: AppColor.primary,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 14),
                                        buildQuestionArea(),
                                        if (mediaUrl != null) ...[
                                          const SizedBox(height: 28),
                                          buildMedia(mediaUrl),
                                        ],
                                        const SizedBox(height: 18),
                                        if (isMultiSelect &&
                                            !_answerRevealed) ...[
                                          Text(
                                            'Selecciona una o más opciones',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],

                                        // Layout Dinamico
                                        LayoutBuilder(
                                          builder: (context, inner) {
                                            final availableWidth =
                                                inner.maxWidth;
                                            final optionWidth =
                                                (availableWidth - 32) /
                                                (answers.length == 1 ? 1 : 2);
                                            return Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 0,
                                              runSpacing: 0,
                                              children: List.generate(
                                                answers.length,
                                                (i) =>
                                                    buildOption(i, optionWidth),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        if (isMultiSelect && !_answerRevealed)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: SafeArea(
                              top: false,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: PrimaryButton(
                                    onPressed: canSubmitMulti
                                        ? () => _submitAnswer(
                                              _selectedIndexes.toList()
                                                ..sort(),
                                            )
                                        : null,
                                    icon: Icons.send_rounded,
                                    label:
                                        'Enviar (${_selectedIndexes.length})',
                                  ),
                                ),
                              ),
                            ),
                          ),

                        if (canShowReviewUi)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.35),
                                child: Center(
                                  child: SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      alignment: Alignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _reviewController,
                                          builder: (context, child) =>
                                              CircularProgressIndicator(
                                                value: _reviewController.value,
                                                strokeWidth: 8,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Colors.white,
                                                    ),
                                              ),
                                        ),
                                        Icon(
                                          _displayedEvaluated?.wasCorrect ==
                                                  true
                                              ? Icons.check
                                              : (b
                                                            .lastResult
                                                            ?.evaluatedAnswer
                                                            .wasCorrect ==
                                                        true
                                                    ? Icons.check
                                                    : Icons.close),
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: SafeArea(
                            child: SecondaryButton(
                              expanded: false,
                              icon: Icons.exit_to_app_rounded,
                              label: 'Salir',
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
