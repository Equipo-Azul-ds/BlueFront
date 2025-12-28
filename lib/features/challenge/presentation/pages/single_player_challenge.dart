import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';
import '../blocs/single_player_challenge_bloc.dart';
import 'single_player_challenge_results.dart';

const Color _optionBlue = Color(0xFF1C6BFF);
const Color _optionRed = Color(0xFFFF5C7A);
const Color _optionGreen = Color(0xFF34C759);
const Color _optionYellow = Color(0xFFFFC857);

const List<Color> optionColors = [
  _optionBlue,
  _optionRed,
  _optionGreen,
  _optionYellow,
];
const List<IconData> optionIcons = [
  Icons.change_history_rounded,
  Icons.diamond_outlined,
  Icons.circle_outlined,
  Icons.square_outlined,
];

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

  int? _selectedIndex;
  bool _answerRevealed = false;
  bool _hasEvaluation = false;
  Timer? _countdownTimer;
  int _timeRemaining = 0;
  Timer? _autoAdvanceTimer;
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo iniciar el juego: $error')),
          );
          Navigator.of(context).pop();
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
      _selectedIndex = null;
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
    _countdownTimer?.cancel();
    _timeRemaining = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _timeRemaining = _timeRemaining - 1;
      });
      if (_timeRemaining <= 0) {
        t.cancel();
        _onTimeExpired();
      }
    });
  }

  // _onTimeExpired: tiempo agotado -> enviamos null como respuesta.
  void _onTimeExpired() {
    _submitAnswer(null);
  }

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    if (_reviewController.isAnimating) {
      _reviewController.stop();
      _reviewController.reset();
    }
  }

  // _submitAnswer: construye PlayerAnswer con el tiempo usado y llama
  // al BLoC. Muestra la UI de revisión y arranca el AnimationController
  // que mostrará el progreso circular durante el periodo de review.
  Future<void> _submitAnswer(int? selectedIdx) async {
    final currentDisplayed = _displayedSlide ?? bloc.currentSlide;
    if (bloc.currentGame == null || currentDisplayed == null) return;

    if (_answerRevealed) return;

    final totalSeconds = currentDisplayed.timeLimitSeconds;
    final timeUsedSeconds = totalSeconds - _timeRemaining;
    final timeUsedMs = (timeUsedSeconds * 1000).round();
    final serverAnswerIndex = selectedIdx == null
        ? null
        : _serverIndexForButton(currentDisplayed, selectedIdx);

    final playerAnswer = PlayerAnswer(
      slideId: currentDisplayed.slideId,
      answerIndex: serverAnswerIndex == null ? null : [serverAnswerIndex],
      timeUsedMs: timeUsedMs,
    );

    setState(() {
      _selectedIndex = selectedIdx;
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
        _selectedIndex = null;
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
          builder: (_) =>
              SinglePlayerChallengeResultsScreen(
            gameId: currentGame.gameId,
            initialSummaryGame: currentGame,
          ),
        ),
      );
      return;
    }

    setState(() {
      _displayedSlide = bloc.currentSlide;
      _selectedIndex = null;
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

          // Construye las opciones
          Widget buildOption(int idx, double optionWidth) {
            final ansText = answers[idx].text ?? '';
            final baseColor = optionColors[idx % optionColors.length];
            final icon = optionIcons[idx % optionIcons.length];

            final bool isSelected = _selectedIndex == idx;
            final bool reveal = _answerRevealed;
            final int? correctIdx =
                _buttonIndexForServer(answers, b.lastCorrectIndex);
            final bool isCorrect = reveal && correctIdx != null && correctIdx == idx;

            Color backgroundColor = baseColor;
            IconData? indicatorIcon;
            if (reveal) {
              backgroundColor = isCorrect
                  ? AppColor.success
                  : (isSelected ? AppColor.error : baseColor);
              indicatorIcon = isCorrect ? Icons.check : Icons.close;
            }

            return SizedBox(
              width: optionWidth,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: reveal
                      ? null
                      : () {
                          _countdownTimer?.cancel();
                          _submitAnswer(idx);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 50,
                      horizontal: 10,
                    ),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ansText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      if (reveal) ...[
                        const SizedBox(width: 8),
                        Icon(indicatorIcon, size: 24),
                      ],
                    ],
                  ),
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
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                qText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColor.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }

          // Barra para mostrar resultados
          Widget buildReviewBar() {
            final bool isCorrect =
                _displayedEvaluated?.wasCorrect ??
                (b.lastResult?.evaluatedAnswer.wasCorrect ?? false);
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
                      isCorrect ? 'Correcto' : 'Incorrecto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                        SafeArea(
                          child: Column(
                            key: ValueKey<String>(slide.slideId),
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: _answerRevealed ? 0 : 20.0,
                                ),
                                child: Column(
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
                                      const SizedBox(height: 50),
                                      buildMedia(mediaUrl),
                                    ],
                                  ],
                                ),
                              ),

                              // Layoyt Dinamico
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final optionWidth =
                                      (availableWidth - 32) /
                                      (answers.length == 1 ? 1 : 2);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 8.0,
                                    ),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 0,
                                      runSpacing: 0,
                                      children: List.generate(
                                        answers.length,
                                        (i) => buildOption(i, optionWidth),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
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
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColor.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Salir'),
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
