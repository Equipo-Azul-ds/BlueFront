import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/SinglePlayerGame.dart';
import '../../domain/repositories/SinglePlayerGameRepository.dart';
import '../../infrastructure/repositories/SinglePlayerGameRepositoryImpl.dart';

/// Modelos que reflejan la estructura de dominio `Question`/`Answer` usada
/// por la UI y el bloc
class AnswerModel {
  final String answerId;
  final String text;
  final String? mediaUrl;
  final bool isCorrect;

  AnswerModel({required this.answerId, required this.text, this.mediaUrl, this.isCorrect = false});
}

class QuestionModel {
  final String questionId;
  final String quizId;
  final String text;
  final String? mediaUrl;
  final String type; // 'quiz' | 'true_false'
  final int timeLimit;
  final int points;
  final List<AnswerModel> answers;

  QuestionModel({
    required this.questionId,
    required this.quizId,
    required this.text,
    this.mediaUrl,
    this.type = 'quiz',
    this.timeLimit = 20,
    this.points = 1000,
    required this.answers,
  });
}

class SinglePlayerChallengeBloc extends ChangeNotifier {
  final SinglePlayerGameRepository repository;

  SinglePlayerChallengeBloc({required this.repository});

  // Interfaz (UI)
  List<QuestionModel> questions = [];
  int currentIndex = 0;
  int timeRemaining = 20;
  int score = 0;
  int correctAnswers = 0;
  int? selectedIndex;
  bool answerRevealed = false;
  int scoreGainedForDisplay = 0;
  int? correctAnswerIndex;

  Timer? _timer;
  SinglePlayerGame? game;
  Map<String, dynamic>? _pendingNextQuestionPayload;

  // Empieza el juego
  Future<void> startGame({required String quizId, required String playerId, required List<QuestionModel> initialQuestions, int? totalQuestions}) async {
    // preferencia por flujo conducido por servidor si la implementación
    // del repositorio lo soporta
    final createTotal = totalQuestions ?? initialQuestions.length;
    game = await repository.createGame(quizId: quizId, playerId: playerId, totalQuestions: createTotal);
    if (repository is SinglePlayerGameRepositoryImpl) {
      final impl = repository as SinglePlayerGameRepositoryImpl;
      final payload = impl.getNextQuestionPayload(game!.gameId);
      if (payload != null) {
        questions = [
          QuestionModel(
            questionId: payload['questionId'] as String,
            quizId: payload['quizId'] as String,
            text: payload['text'] as String,
            mediaUrl: payload['mediaUrl'] as String?,
            type: payload['type'] as String? ?? 'quiz',
            timeLimit: payload['timeLimit'] as int? ?? 20,
            points: payload['points'] as int? ?? 1000,
            answers: (payload['answers'] as List<dynamic>).map((a) => AnswerModel(answerId: a['answerId'] as String, text: a['text'] as String, mediaUrl: a['mediaUrl'] as String?, isCorrect: a['isCorrect'] as bool? ?? false)).toList(),
          )
        ];
      } else {
        questions = initialQuestions;
      }
    } else {
      questions = initialQuestions;
    }
    currentIndex = 0;
    score = 0;
    correctAnswers = 0;
    selectedIndex = null;
    answerRevealed = false;
    correctAnswerIndex = null;
    scoreGainedForDisplay = 0;
    startTimer();
    notifyListeners();
  }

  void startTimer() {
    timeRemaining = 20;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!answerRevealed) {
        if (timeRemaining > 0) {
          timeRemaining--;
          notifyListeners();
        } else {
          _timer?.cancel();
          revealAnswer();
        }
      }
    });
  }

  void disposeTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> selectAnswer(int index) async {
    if (answerRevealed) return;
    _timer?.cancel();
    selectedIndex = index;
    await revealAnswer();
    notifyListeners();
  }

  Future<void> revealAnswer() async {
    if (answerRevealed) return;
    final q = questions[currentIndex];
    answerRevealed = true;

    // Construye la respuesta del jugador (frontend envía sólo índices y tiempo usado)
    final playerAnswer = PlayerAnswer(answerIndex: selectedIndex == null ? null : [selectedIndex!], timeUsedMs: (q.timeLimit - timeRemaining) * 1000);

    if (game != null) {
      try {
        final evaluated = await repository.submitAnswer(game!.gameId, q.questionId, playerAnswer);

        // Actualiza el estado local de la UI según la evaluación retornada por el servidor
        score += evaluated.evaluatedAnswer.pointsEarned;
        if (evaluated.evaluatedAnswer.wasCorrect) correctAnswers++;
        scoreGainedForDisplay = evaluated.evaluatedAnswer.pointsEarned;

        // Si se está usando la implementación mock, intenta obtener el siguiente payload desde ésta
        if (repository is SinglePlayerGameRepositoryImpl) {
          final impl = repository as SinglePlayerGameRepositoryImpl;
          _pendingNextQuestionPayload = impl.getNextQuestionPayload(game!.gameId);
          correctAnswerIndex = impl.getCorrectAnswerIndex(game!.gameId, q.questionId);
        }
      } catch (_) {
        // ignorar errores del repositorio en modo mock
      }
    }

    notifyListeners();
  }

  Future<void> nextOrFinish(void Function() onFinish) async {
    if (_pendingNextQuestionPayload != null) {
      final payload = _pendingNextQuestionPayload!;
      final qm = QuestionModel(
        questionId: payload['questionId'] as String,
        quizId: payload['quizId'] as String,
        text: payload['text'] as String,
        mediaUrl: payload['mediaUrl'] as String?,
        type: payload['type'] as String? ?? 'quiz',
        timeLimit: payload['timeLimit'] as int? ?? 20,
        points: payload['points'] as int? ?? 1000,
        answers: (payload['answers'] as List<dynamic>).map((a) => AnswerModel(answerId: a['answerId'] as String, text: a['text'] as String, mediaUrl: a['mediaUrl'] as String?, isCorrect: a['isCorrect'] as bool? ?? false)).toList(),
      );
      questions.add(qm);
      currentIndex++;
      selectedIndex = null;
      answerRevealed = false;
      correctAnswerIndex = null;
      scoreGainedForDisplay = 0;
      _pendingNextQuestionPayload = null;
      startTimer();
      notifyListeners();
      return;
    }

    if (currentIndex < questions.length - 1) {
      currentIndex++;
      selectedIndex = null;
      answerRevealed = false;
      scoreGainedForDisplay = 0;
      startTimer();
      notifyListeners();
    } else {
      // completar juego en el repositorio
      if (game != null) {
        try {
          await repository.completeGame(game!.gameId);
        } catch (_) {}
      }
      onFinish();
    }
  }

  @override
  void dispose() {
    disposeTimer();
    super.dispose();
  }
}
