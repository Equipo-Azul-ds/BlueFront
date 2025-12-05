import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'player_results_screen.dart';

const Color _optionBlue = Color(0xFF1C6BFF);
const Color _optionRed = Color(0xFFFF5C7A);
const Color _optionGreen = Color(0xFF34C759);
const Color _optionYellow = Color(0xFFFFC857);

const List<Color> _optionColors = [
  _optionBlue,
  _optionRed,
  _optionGreen,
  _optionYellow,
];

const List<IconData> _optionIcons = [
  Icons.change_history_rounded,
  Icons.diamond_outlined,
  Icons.circle_outlined,
  Icons.square_outlined,
];

class PlayerQuestionScreen extends StatefulWidget {
  final String nickname;
  final String quizTitle;
  final List<Map<String, dynamic>> questions;
  final int currentIndex;
  final List<bool?> answerProgress;
  final int basePointsPerQuestion;

  const PlayerQuestionScreen({
    super.key,
    required this.nickname,
    required this.quizTitle,
    required this.questions,
    required this.currentIndex,
    required this.answerProgress,
    required this.basePointsPerQuestion,
  });

  @override
  State<PlayerQuestionScreen> createState() => _PlayerQuestionScreenState();
}

class _PlayerQuestionScreenState extends State<PlayerQuestionScreen>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> _question;
  late final List<bool?> _progress;
  late int _timeRemaining;
  Timer? _countdownTimer;
  late final AnimationController _reviewController;

  int? _selectedIndex;
  bool _answerRevealed = false;
  bool? _wasCorrect;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _question = widget.questions[widget.currentIndex];
    _progress = List<bool?>.from(widget.answerProgress);
    _timeRemaining = (_question['time'] as int?) ?? 20;
    _reviewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _answerRevealed) {
          _advanceAfterReview();
        }
      });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeRemaining <= 1) {
        timer.cancel();
        setState(() => _timeRemaining = 0);
        if (!_answerRevealed) {
          _revealAnswer(null);
        }
      } else {
        setState(() => _timeRemaining--);
      }
    });
  }

  void _handleOptionTap(int index) {
    if (_answerRevealed) return;
    _revealAnswer(index);
  }

  void _revealAnswer(int? selectedIndex) {
    _countdownTimer?.cancel();
    final answers = _question['answers'] as List<dynamic>;
    final bool wasCorrect = selectedIndex != null
        ? (answers[selectedIndex]['correct'] as bool)
        : false;

    setState(() {
      _selectedIndex = selectedIndex;
      _answerRevealed = true;
      _wasCorrect = wasCorrect;
      _progress[widget.currentIndex] = wasCorrect ? true : false;
    });

    _reviewController.forward(from: 0);
  }

  void _advanceAfterReview() {
    if (_navigated) return;
    final bool hasNext = widget.currentIndex < widget.questions.length - 1;
    if (hasNext) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PlayerQuestionScreen(
            nickname: widget.nickname,
            quizTitle: widget.quizTitle,
            questions: widget.questions,
            currentIndex: widget.currentIndex + 1,
            answerProgress: _progress,
            basePointsPerQuestion: widget.basePointsPerQuestion,
          ),
        ),
      );
    } else {
      _goToResults();
    }
  }

  void _goToResults() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PlayerResultsScreen(
          nickname: widget.nickname,
          quizTitle: widget.quizTitle,
          answersProgress: _progress,
          basePointsPerQuestion: widget.basePointsPerQuestion,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  Widget _buildReviewBanner() {
    final bool correct = _wasCorrect ?? false;
    final String subtitle = correct
        ? '+${widget.basePointsPerQuestion} puntos'
        : '0 puntos en esta pregunta';
    return Container(
      width: double.infinity,
      color: correct ? AppColor.success : AppColor.error,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            correct ? 'Correcto' : 'Incorrecto',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(String text, String contextLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            contextLabel,
            style: const TextStyle(
              color: AppColor.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColor.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    int idx,
    List<dynamic> answers,
    double optionWidth,
  ) {
    final String ansText = answers[idx]['text'] as String;
    final baseColor = _optionColors[idx % _optionColors.length];
    final icon = _optionIcons[idx % _optionIcons.length];
    final bool isSelected = _selectedIndex == idx;
    final bool reveal = _answerRevealed;
    final bool isCorrect = answers[idx]['correct'] as bool;

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
          onPressed: reveal ? null : () => _handleOptionTap(idx),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
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

  @override
  Widget build(BuildContext context) {
    final answers = _question['answers'] as List<dynamic>;
    final mediaUrl = _question['media'] as String?;
    final questionLabel = 'Pregunta ${widget.currentIndex + 1} de ${widget.questions.length}';

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
            if (_answerRevealed) _buildReviewBanner(),
            Expanded(
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: _answerRevealed ? 0 : 20.0,
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.quizTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                questionLabel,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                              _buildQuestionArea(
                                _question['question'] as String,
                                _question['context'] as String? ?? widget.quizTitle,
                              ),
                              if (mediaUrl != null) ...[
                                const SizedBox(height: 40),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      mediaUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                            height: 200,
                                            color: Colors.black.withValues(alpha: 0.15),
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported_outlined,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                                  (i) => _buildOption(
                                    i,
                                    answers,
                                    optionWidth,
                                  ),
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
                                          const AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  ),
                                  Icon(
                                    (_wasCorrect ?? false)
                                        ? Icons.check
                                        : Icons.close,
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
                        onPressed: () => Navigator.of(context).pop(),
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
  }
}
