import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'single_player_challenge_results.dart';
import '../blocs/single_player_challenge_bloc.dart';
import '../../domain/repositories/SinglePlayerGameRepository.dart';

// Colores
const Color red = Color(0xFFE53935);
const Color blue = Color(0xFF1E88E5);
const Color yellow = Color(0xFFFFB300);
const Color green = Color(0xFF43A047);
const Color purpleDark = Color(0xFF4B0082);
const Color purpleLight = Color(0xFF8A2BE2);

// Lista de Colores e Iconos
const List<Color> optionColors = [red, blue, yellow, green];
const List<IconData> optionIcons = [
  Icons.change_history_rounded,
  Icons.diamond_outlined,
  Icons.circle_outlined,
  Icons.square_outlined
];

class SinglePlayerChallengeScreen extends StatefulWidget {
  final String nickname;
  const SinglePlayerChallengeScreen({super.key, required this.nickname});

  @override
  State<SinglePlayerChallengeScreen> createState() => _SinglePlayerChallengeScreenState();
}

class _SinglePlayerChallengeScreenState extends State<SinglePlayerChallengeScreen> {
  late final SinglePlayerChallengeBloc bloc;

  @override
  void initState() {
    super.initState();
  }

  bool _blocInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_blocInitialized) {
      final repo = Provider.of<SinglePlayerGameRepository>(context, listen: false);
      bloc = SinglePlayerChallengeBloc(repository: repo);

      // Empieza el juego
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bloc.startGame(quizId: 'mock_quiz_1', playerId: widget.nickname, initialQuestions: [], totalQuestions: 4);
      });

      _blocInitialized = true;
    }
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SinglePlayerChallengeBloc>.value(
      value: bloc,
      child: Consumer<SinglePlayerChallengeBloc>(
        builder: (context, b, _) {
          if (b.questions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

          final q = b.questions[b.currentIndex];

            Widget buildOption(int idx, double optionWidth) {
            final ans = q.answers[idx];
            final text = ans.text;
            final baseColor = optionColors[idx % optionColors.length];
            final icon = optionIcons[idx % optionIcons.length];
            final isSelected = b.selectedIndex == idx;
            // Determina la respuesta correcta de la respuesta que envia la API
            final isCorrect = (b.correctAnswerIndex != null) ? (b.correctAnswerIndex == idx) : ans.isCorrect;
            Color backgroundColor = baseColor;
            IconData? indicatorIcon;
            if (b.answerRevealed) {
              backgroundColor = isCorrect ? green : (isSelected ? red : baseColor);
              indicatorIcon = isCorrect ? Icons.check : Icons.close;
            }

            return SizedBox(
              width: optionWidth,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: b.answerRevealed ? null : () => b.selectAnswer(idx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      if (b.answerRevealed) ...[
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Text(
                q.text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: purpleDark, fontSize: 24, fontWeight: FontWeight.w800),
              ),
            );
          }

          Widget buildReviewBar() {
            final isCorrect = b.selectedIndex != null && (b.correctAnswerIndex != null ? b.correctAnswerIndex == b.selectedIndex : q.answers[b.selectedIndex!].isCorrect);
            final pointsEarned = isCorrect ? b.scoreGainedForDisplay : 0;
            return Container(
              width: double.infinity,
              color: isCorrect ? green : red,
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Column(
                  children: [
                    Text(isCorrect ? 'Correcto' : 'Incorrecto', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isCorrect) Text('+$pointsEarned', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [purpleLight, purpleDark])),
              child: Column(
                children: [
                  if (b.answerRevealed) buildReviewBar(),
                  Expanded(
                    child: Stack(
                      children: [
                        SafeArea(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {        
                              final isIncoming = child.key == ValueKey<String>(q.questionId);
                              final Tween<Offset> offsetTween = isIncoming
                                  ? Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                  : Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0));
                              final opacityAnim = CurvedAnimation(
                                parent: animation,
                                curve: isIncoming ? Curves.linear : const Interval(0.0, 0.9),
                              );
                              return FadeTransition(
                                opacity: opacityAnim,
                                child: SlideTransition(
                                  position: animation.drive(offsetTween),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey<String>(q.questionId),
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: b.answerRevealed ? 0 : 20.0),
                                  child: Column(
                                    children: [
                                      if (!b.answerRevealed)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 2)),
                                          child: Text('${b.timeRemaining}', style: const TextStyle(color: purpleDark, fontSize: 28, fontWeight: FontWeight.bold)),
                                        ),
                                      const SizedBox(height: 14),
                                      if (q.mediaUrl != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(q.mediaUrl!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 160, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image)))),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      buildQuestionArea(),
                                    ],
                                  ),
                                ),

                                // Layoyt Dinamico
                                LayoutBuilder(builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final optionWidth = (availableWidth - 32) / (q.answers.length == 1 ? 1 : 2);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 0,
                                      runSpacing: 0,
                                      children: List.generate(q.answers.length, (i) => buildOption(i, optionWidth)),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),

                        if (b.answerRevealed)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: SafeArea(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await b.nextOrFinish(() {
                                    final gameId = b.game?.gameId;
                                    if (gameId != null) {
                                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SinglePlayerChallengeResultsScreen(gameId: gameId)));
                                    } else {
                                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SinglePlayerChallengeResultsScreen(gameId: '')));
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: purpleDark, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                child: const Text('Siguiente'),
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
