import 'Answer.dart';

class Question {
  final String questionId;
  final String quizId;
  final String text;
  final String? mediaUrl;
  final String type; //'quiz', 'true_false'
  final int timeLimit; //en segundos
  final int points;
  final List<Answer> answers;

  Question({
    required this.questionId,
    required this.quizId,
    required this.text,
    required this.mediaUrl,
    required this.type,
    required this.timeLimit,
    required this.points,
    required this.answers
  }){
    _validate();
  }

  void _validate(){
    if (type == 'quiz'){
      if (answers.length < 2 || answers.length > 4){
        throw AssertionError('Una pregunta de tipo quiz debe tener entre 2 y 4 respuestas.');
      }
    }else if (type == 'true_false'){
      if (answers.length != 2){
        throw AssertionError('Una pregunta de tipo true_false debe tener exactamente 2 respuestas.');
      }
    }
    if (!answers.any((a)=>a.isCorrect)){
      throw AssertionError('Debe haber al menos una respuesta correcta.');
    }
  }

  factory Question.fromJson(Map<String, dynamic> json){
    return Question(
      questionId: json['questionId'] ?? json['id'],
      quizId: json['quizId'] ?? json['quiz_id'] ?? '', // Default to empty if missing
      text: json['text'] ?? json['questionText'] ?? json['question_text'] ?? '',
      // Prioritize mediaId (UUID) over mediaUrl (Display URL) to ensure persistence of the Asset ID.
      // The UI must resolve this ID to a URL for display if needed.
      mediaUrl: json['mediaId'] ?? json['media_id'] ?? json['mediaUrl'],
      type: json['type'] ?? json['questionType'] ?? json['question_type'] ?? 'quiz',
      timeLimit: (json['timeLimit'] ?? json['time_limit'] ?? 30) as int,
      points: (json['points'] ?? json['points'] ?? 0) as int,
      answers: (json['answers'] as List).map((a) => Answer.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'questionId': questionId,
      'quizId': quizId,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type,
      'timeLimit': timeLimit,
      'points': points,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}