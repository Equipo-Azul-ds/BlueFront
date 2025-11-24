import 'package:flutter/material.dart';
import 'single_player_leaderboard.dart';
import 'dart:async';

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

// Mock de una entidad Quiz incompleto, es solo para jugar con la pantalla
class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final int points;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.points = 1000,
  });
}

class SinglePlayerChallengeScreen extends StatefulWidget {
  final String nickname;
  const SinglePlayerChallengeScreen({super.key, required this.nickname});

  @override
  State<SinglePlayerChallengeScreen> createState() => SinglePlayerChallengeScreenState();
}

class SinglePlayerChallengeScreenState extends State<SinglePlayerChallengeScreen> {
  // Mock de un Quiz
  final List<Question> quiz = [
    Question(
      text: 'Cual es la capital de Francia?',
      options: ['Berlin', 'Madrid', 'Paris', 'Rome'],
      correctAnswerIndex: 2,
    ),
    Question(
      text: 'Que Planeta es conocido como el mas Rojo?',
      options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      correctAnswerIndex: 1,
    ),
    Question(
      text: 'Cuanto es 788 + 160?',
      options: ['948', '958', '938', '1048'],
      correctAnswerIndex: 0,
    ),
  ];

  int currentQuestionIndex = 0;
  int score = 0;
  int correctAnswersCount = 0;
  int? selectedAnswerIndex;
  bool answerRevealed = false;
  int timeRemaining = 20;
  Timer? timer;
  int scoreGainedForDisplay = 0; 

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timeRemaining = 20;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!answerRevealed) {
        setState(() {
          if (timeRemaining > 0) {
            timeRemaining--;
          } else {
            timer?.cancel();
            revealAnswer();
          }
        });
      }
    });
  }

  void handleAnswerSelection(int index) {
    if (answerRevealed) return;
    timer?.cancel(); 
    setState(() {
      selectedAnswerIndex = index;
      revealAnswer();
    });
  }

  void revealAnswer() {
    if (answerRevealed) return;
    final Question currentQuestion = quiz[currentQuestionIndex];
    int pointsEarned = 0;
    if (selectedAnswerIndex != null && selectedAnswerIndex == currentQuestion.correctAnswerIndex) {
      // Simple calculo en base al valor de la pregunta + tiempo restante
      pointsEarned = (currentQuestion.points * (timeRemaining / 20)).round();
      score += pointsEarned;
      correctAnswersCount++;
    }

    setState(() {
      answerRevealed = true;
      scoreGainedForDisplay = pointsEarned; // Aqui guarda el puntaje para mostrarlo a la hora de marcar una respuesta
    });
  }

  void goToNextQuestionOrLeaderboard() {
    if (currentQuestionIndex < quiz.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
        answerRevealed = false;
        scoreGainedForDisplay = 0;
        startTimer();
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SinglePlayerLeaderboardScreen(
            nickname: widget.nickname,
            finalScore: score,
            totalQuestions: quiz.length,
            correctAnswers: correctAnswersCount,
          ),
        ),
      );
    }
  }

  // Widgets

  Widget buildOptionButton(String text, int index) {
    final Question currentQuestion = quiz[currentQuestionIndex];
    final Color baseColor = optionColors[index];
    final IconData icon = optionIcons[index];
    final bool isCorrect = index == currentQuestion.correctAnswerIndex;
    final bool isSelected = index == selectedAnswerIndex;
    Color backgroundColor = baseColor;
    IconData? indicatorIcon;
    
    if (answerRevealed) {
      backgroundColor = isCorrect ? green : (isSelected ? red : baseColor);
      indicatorIcon = isCorrect ? Icons.check : Icons.close;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: answerRevealed ? null : () => handleAnswerSelection(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            minimumSize: const Size.fromHeight(100),
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
              if (answerRevealed) ...[
                const SizedBox(width: 8),
                Icon(indicatorIcon, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQuestionArea(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        question.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: purpleDark,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildReviewBar() {
    final bool isCorrect = selectedAnswerIndex == quiz[currentQuestionIndex].correctAnswerIndex;
    final int pointsEarned = isCorrect ? scoreGainedForDisplay : 0; 

    return Container(
      width: double.infinity,
      color: isCorrect ? green : red,
      padding: const EdgeInsets.all(15),
      child: Center(
        child: Column(
          children: [
            Text(
              isCorrect ? 'Correcto' : 'Incorrecto',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isCorrect)
              Text(
                '+$pointsEarned',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Question currentQuestion = quiz[currentQuestionIndex];
    
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
            // Barra de respuesta
            if (answerRevealed) buildReviewBar(),
            
            Expanded(
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Temporizador y area de respuestas
                        Padding(
                          padding: EdgeInsets.only(top: answerRevealed ? 0 : 20.0),
                          child: Column(
                            children: [
                              // Icono de tiempo
                              if (!answerRevealed)
                                Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white54, width: 2),
                                  ),
                                  child: Text(
                                    '$timeRemaining',
                                    style: const TextStyle(
                                      color: purpleDark,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              // Texto de la pregunta
                              buildQuestionArea(currentQuestion),
                            ],
                          ),
                        ),

                        // Grid de respuestas
                        Column(
                          children: [
                            Row(
                              children: [
                                buildOptionButton(currentQuestion.options[0], 0),
                                buildOptionButton(currentQuestion.options[1], 1),
                              ],
                            ),
                            Row(
                              children: [
                                buildOptionButton(currentQuestion.options[2], 2),
                                buildOptionButton(currentQuestion.options[3], 3),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Boton Siguiente
                  if (answerRevealed)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: SafeArea(
                        child: ElevatedButton(
                          onPressed: goToNextQuestionOrLeaderboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: purpleDark,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
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
  }
}