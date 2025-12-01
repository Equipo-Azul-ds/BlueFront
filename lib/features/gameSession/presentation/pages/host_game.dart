import 'package:flutter/material.dart';
import 'multiplayer_leaderboard.dart';

const Color kPurple = Color(0xFF46178F);
const Color kDarkPurple = Color(0xFF25076B);
const Color kRed = Color(0xFFE21B3C);
const Color kBlue = Color(0xFF1368CE);
const Color kYellow = Color(0xFFD89E00);
const Color kGreen = Color(0xFF26890C);

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  // 1. State Variables
  int currentQuestionIndex = 0;
  bool isStatsView = false; // Toggles between Question and Bar Chart

  // 2. Mock Data: List of Questions
  final List<Map<String, dynamic>> questions = [
    {
      "question": "What is the capital of France?",
      "time": 20,
      "answers": [
        {"text": "London", "color": kRed, "correct": false},
        {"text": "Berlin", "color": kBlue, "correct": false},
        {"text": "Madrid", "color": kYellow, "correct": false},
        {"text": "Paris", "color": kGreen, "correct": true},
      ],
      "stats": [2, 5, 1, 15] // Mock stats for the bar chart
    },
    {
      "question": "Which planet is known as the Red Planet?",
      "time": 15,
      "answers": [
        {"text": "Mars", "color": kRed, "correct": true},
        {"text": "Venus", "color": kBlue, "correct": false},
        {"text": "Jupiter", "color": kYellow, "correct": false},
        {"text": "Saturn", "color": kGreen, "correct": false},
      ],
      "stats": [20, 3, 2, 1]
    },
     {
      "question": "Wawa?",
      "time": 10,
      "answers": [
        {"text": "Waawa", "color": kRed, "correct": false},
        {"text": "Wjananf", "color": kBlue, "correct": true},
        {"text": "Dbsbs", "color": kYellow, "correct": false},
        {"text": "Eueusj", "color": kGreen, "correct": false},
      ],
      "stats": [1, 20, 5, 2]
    },
  ];

  void _handleNextAction() {
    if (isStatsView) {
      // If we are looking at stats, "Next" means go to next question OR Leaderboard
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          isStatsView = false;
        });
      } else {
        // End of game
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MultiplayerLeaderboardScreen(
              nickname: "Player 1",
              finalScore: 2500,
              totalQuestions: 3,
              correctAnswers: 3,
            ),
          ),
        );
      }
    } else {
      // If we are looking at the question, "Skip" (or Time Up) means show stats
      setState(() {
        isStatsView = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = questions[currentQuestionIndex];
    final List<dynamic> answers = currentQ['answers'];
    final List<int> stats = currentQ['stats'];

    return Scaffold(
      backgroundColor: kDarkPurple,
      appBar: AppBar(
        backgroundColor: kPurple,
        automaticallyImplyLeading: false,
        title: Text(
          "${currentQuestionIndex + 1} of ${questions.length}",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _handleNextAction,
            child: Text(
              isStatsView ? "Next" : "Skip",
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Question Text Area
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            alignment: Alignment.center,
            child: Text(
              currentQ['question'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Main Content Area (Timer/Image OR Bar Chart)
          Expanded(
            child: isStatsView 
              ? _buildStatsView(stats, answers) // Show Bar Chart
              : _buildQuestionView(currentQ['time']), // Show Timer & Image
          ),

          // Answers Area
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildAnswerTile(answers[0], isStatsView),
                      _buildAnswerTile(answers[2], isStatsView),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildAnswerTile(answers[1], isStatsView),
                      _buildAnswerTile(answers[3], isStatsView),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Views ---

  Widget _buildQuestionView(int time) {
    return Row(
      children: [
        // Left Side (Timer)
        SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: kPurple,
                child: Text(
                  "$time",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                "0",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text("Answers", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Center Content (Image Placeholder)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: kPurple.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Center(
                child: Icon(Icons.image, size: 80, color: Colors.white24),
              ),
            ),
          ),
        ),
        const SizedBox(width: 80), // Balance Layout
      ],
    );
  }

  Widget _buildStatsView(List<int> stats, List<dynamic> answers) {
    // Find the highest vote to scale the bars relative to max height
    int maxVotes = stats.reduce((curr, next) => curr > next ? curr : next);
    if(maxVotes == 0) maxVotes = 1; // Prevent division by zero

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          final color = (answers[index]['color'] as Color);
          final isCorrect = answers[index]['correct'] as bool;
          final count = stats[index];
          
          // Calculate height percentage (min 10% visibility)
          double heightPct = (count / maxVotes); 
          if(heightPct < 0.1) heightPct = 0.1;

          return _buildBar(color, heightPct, count, isCorrect);
        }),
      ),
    );
  }

  Widget _buildBar(Color color, double heightPct, int count, bool isCorrect) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isCorrect) 
            const Icon(Icons.check, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          
          // The Bar
          LayoutBuilder(
            builder: (context, constraints) {
               // Max height available for bars inside the Expanded row
               // We use a fixed factor of 250 for simplicity in this demo context
               return Container(
                width: 50,
                height: 200 * heightPct, 
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
                ),
              );
            }
          ),
          
          const SizedBox(height: 5),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
          if (!isCorrect)
            Icon(Icons.close, color: Colors.white.withOpacity(0.5), size: 20),
          
          Text(
            "$count",
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerTile(Map<String, dynamic> answerData, bool dimIncorrect) {
    final Color color = answerData['color'];
    final String text = answerData['text'];
    final bool isCorrect = answerData['correct'];

    // In stats view, dim incorrect answers
    final double opacity = (dimIncorrect && !isCorrect) ? 0.4 : 1.0;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        color: color.withOpacity(opacity),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            // Icon based on shape convention (Red=Triangle, Blue=Diamond, etc)
            _getIconForColor(color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dimIncorrect && isCorrect)
              const Icon(Icons.check, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _getIconForColor(Color c) {
    IconData i = Icons.help;
    if (c == kRed) i = Icons.change_history; // Triangle
    if (c == kBlue) i = Icons.diamond_outlined; // Diamond
    if (c == kYellow) i = Icons.circle_outlined; // Circle
    if (c == kGreen) i = Icons.square_outlined; // Square
    return Icon(i, color: Colors.white);
  }
}