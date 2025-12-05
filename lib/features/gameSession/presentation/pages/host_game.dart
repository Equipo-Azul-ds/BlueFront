import 'package:flutter/material.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../mocks/mock_session_data.dart';
import 'host_results_screen.dart';

const Color _triangleColor = Color(0xFF1C6BFF);
const Color _diamondColor = Color(0xFFFF5C7A);
const Color _circleColor = Color(0xFF34C759);
const Color _squareColor = Color(0xFFFFC857);
const List<Color> _optionColors = [
  _triangleColor,
  _diamondColor,
  _circleColor,
  _squareColor,
];

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  int currentQuestionIndex = 0;
  bool isStatsView = false;
  final List<Map<String, dynamic>> questions = mockSessionQuestions;
  final List<Map<String, dynamic>> standings = mockSessionStandings;

  void _handleNextAction() {
    if (isStatsView) {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          isStatsView = false;
        });
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HostResultsScreen(
              standings: standings,
              totalQuestions: questions.length,
              quizTitle: mockQuizTitle,
            ),
          ),
        );
      }
    } else {
      setState(() => isStatsView = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = questions[currentQuestionIndex];
    final List<dynamic> rawAnswers = currentQ['answers'] as List<dynamic>;
    final List<Map<String, dynamic>> decoratedAnswers =
        _decorateAnswers(rawAnswers);
    final List<int> stats =
        (currentQ['stats'] as List<dynamic>).cast<int>();

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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mockQuizTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Pregunta ${currentQuestionIndex + 1} de ${questions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentQ['context'] as String,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    FilledButton.tonal(
                      onPressed: _handleNextAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColor.primary,
                      ),
                      child: Text(isStatsView ? 'Siguiente' : 'Mostrar resultados'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _QuestionCard(text: currentQ['question'] as String),
                const SizedBox(height: 14),
                isStatsView
                  ? _StatsCard(stats: stats, answers: decoratedAnswers)
                    : _MediaAndTimerBlock(time: currentQ['time'] as int),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: decoratedAnswers.length,
                    itemBuilder: (_, index) => _AnswerTile(
                      data: decoratedAnswers[index],
                      dimIncorrect: isStatsView,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _decorateAnswers(List<dynamic> rawAnswers) {
    return List<Map<String, dynamic>>.generate(rawAnswers.length, (index) {
      final item = rawAnswers[index] as Map<String, dynamic>;
      return {
        'text': item['text'] as String,
        'correct': item['correct'] as bool,
        'color': _optionColors[index % _optionColors.length],
      };
    });
  }

}

class _QuestionCard extends StatelessWidget {
  final String text;

  const _QuestionCard({required this.text});

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

class _MediaAndTimerBlock extends StatelessWidget {
  final int time;

  const _MediaAndTimerBlock({required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 140,
              color: Colors.white.withValues(alpha: 0.15),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 64,
                width: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 0.85,
                      strokeWidth: 6,
                      color: AppColor.accent,
                      backgroundColor: AppColor.primary.withValues(alpha: 0.1),
                    ),
                    Center(
                      child: Text(
                        '$time s',
                        style: const TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Respuestas en curso',
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

class _StatsCard extends StatelessWidget {
  final List<int> stats;
  final List<dynamic> answers;

  const _StatsCard({required this.stats, required this.answers});

  @override
  Widget build(BuildContext context) {
    final maxVotes = stats.fold<int>(1, (prev, element) => element > prev ? element : prev);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stats.length, (index) {
          final color = answers[index]['color'] as Color;
          final isCorrect = answers[index]['correct'] as bool;
          final count = stats[index];
          final heightFactor = (count / maxVotes).clamp(0.15, 1.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isCorrect)
                const Icon(Icons.check_circle, color: AppColor.success, size: 20)
              else
                const SizedBox(height: 20),
              const SizedBox(height: 6),
              Container(
                width: 50,
                height: 160 * heightFactor,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool dimIncorrect;

  const _AnswerTile({required this.data, required this.dimIncorrect});

  @override
  Widget build(BuildContext context) {
    final color = data['color'] as Color;
    final text = data['text'] as String;
    final isCorrect = data['correct'] as bool;

    final background = dimIncorrect && !isCorrect
        ? color.withValues(alpha: 0.4)
        : color;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _getIconForColor(color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (dimIncorrect && isCorrect)
            const Icon(Icons.check, color: Colors.white),
        ],
      ),
    );
  }

  Icon _getIconForColor(Color c) {
    IconData icon = Icons.help_outline;
    if (c == _triangleColor) icon = Icons.change_history_rounded;
    if (c == _diamondColor) icon = Icons.diamond_outlined;
    if (c == _circleColor) icon = Icons.circle_outlined;
    if (c == _squareColor) icon = Icons.square_outlined;
    return Icon(icon, color: Colors.white);
  }
}
