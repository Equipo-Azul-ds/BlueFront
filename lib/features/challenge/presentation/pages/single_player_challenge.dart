import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'single_player_challenge_results.dart';
import '../blocs/single_player_challenge_bloc.dart';
import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';

const Color red = Color(0xFFE53935);
const Color blue = Color(0xFF1E88E5);
const Color yellow = Color(0xFFFFB300);
const Color green = Color(0xFF43A047);
const Color purpleDark = Color(0xFF4B0082);
const Color purpleLight = Color(0xFF8A2BE2);

const List<Color> optionColors = [red, blue, yellow, green];
const List<IconData> optionIcons = [
  Icons.change_history_rounded,
  Icons.diamond_outlined,
  Icons.circle_outlined,
  Icons.square_outlined,
];

class SinglePlayerChallengeScreen extends StatefulWidget {
  final String nickname;
  final String quizId;
  final int totalQuestions;

  const SinglePlayerChallengeScreen({
    super.key,
    required this.nickname,
    required this.quizId,
    required this.totalQuestions,
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
  Timer? _countdownTimer;
  int _timeRemaining = 0;
  Timer? _autoAdvanceTimer;
  SlideDTO? _displayedSlide;
  SlideDTO? _pendingSlide;
  late final AnimationController _reviewController;
  static const int _reviewDurationMs = 2000;
  EvaluatedAnswer? _displayedEvaluated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_blocInitialized) {
      bloc = Provider.of<SinglePlayerChallengeBloc>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        bloc.startGame(widget.quizId, widget.nickname, widget.totalQuestions);
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
      _displayedSlide = slide;
    });

    if (_displayedSlide != null) {
      _startCountdown(_displayedSlide!.timeLimitSeconds);
    }
  }

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

  Future<void> _submitAnswer(int? selectedIdx) async {
    final currentDisplayed = _displayedSlide ?? bloc.currentSlide;
    if (bloc.currentGame == null || currentDisplayed == null) return;

    if (_answerRevealed) return;

    final totalSeconds = currentDisplayed.timeLimitSeconds;
    final timeUsedSeconds = totalSeconds - _timeRemaining;
    final timeUsedMs = (timeUsedSeconds * 1000).round();

    final playerAnswer = PlayerAnswer(
      answerIndex: selectedIdx == null ? null : [selectedIdx],
      timeUsedMs: timeUsedMs,
    );

    setState(() {
      _selectedIndex = selectedIdx;
      _answerRevealed = true;
      _displayedEvaluated = null;
    });

    await bloc.submitAnswer(playerAnswer);

    setState(() {
      _displayedEvaluated = bloc.lastResult?.evaluatedAnswer;
    });

    if (_reviewController.isAnimating) {
      _reviewController.stop();
    }
    _reviewController.reset();
    _reviewController.forward();
  }

  void _applyPendingOrAdvance() {
    final currentGame = bloc.currentGame;

    if (_pendingSlide != null) {
      setState(() {
        _displayedSlide = _pendingSlide;
        _pendingSlide = null;
        _selectedIndex = null;
        _answerRevealed = false;
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
              SinglePlayerChallengeResultsScreen(gameId: currentGame.gameId),
        ),
      );
      return;
    }

    setState(() {
      _displayedSlide = bloc.currentSlide;
      _selectedIndex = null;
      _answerRevealed = false;
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

          Widget buildOption(int idx, double optionWidth) {
            final ansText = answers[idx].text ?? '';
            final baseColor = optionColors[idx % optionColors.length];
            final icon = optionIcons[idx % optionIcons.length];

            final bool isSelected = _selectedIndex == idx;
            final bool reveal = _answerRevealed;
            final int? correctIdx = b.lastCorrectIndex;
            final bool isCorrect = reveal
                ? (correctIdx != null ? correctIdx == idx : false)
                : false;

            Color backgroundColor = baseColor;
            IconData? indicatorIcon;
            if (reveal) {
              backgroundColor = isCorrect
                  ? green
                  : (isSelected ? red : baseColor);
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
                      vertical: 20,
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
                  color: purpleDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }

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
              color: isCorrect ? green : red,
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

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [purpleLight, purpleDark],
                ),
              ),
              child: Column(
                children: [
                  if (_answerRevealed) buildReviewBar(),
                  Expanded(
                    child: Stack(
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
                                            color: purpleDark,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 14),
                                    if (mediaUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            mediaUrl,
                                            height: 160,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                  height: 160,
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    buildQuestionArea(),
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

                        if (_answerRevealed)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.35),
                                child: Center(
                                  child: SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: Stack(
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
                                foregroundColor: purpleDark,
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
