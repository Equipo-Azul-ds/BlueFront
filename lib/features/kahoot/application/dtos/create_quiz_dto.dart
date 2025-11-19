// DTOs usados por los use-cases (frontend)
class CreateAnswerDto {
  final String? answerText;
  final String? answerImage;
  final bool isCorrect;

  CreateAnswerDto({this.answerText, this.answerImage, required this.isCorrect});

  Map<String, dynamic> toJson() => {
        'answerText': answerText,
        'answerImage': answerImage,
        'isCorrect': isCorrect,
      };
}

class CreateQuestionDto {
  final String questionText;
  final String? mediaUrl;
  final String questionType; // 'quiz' | 'true_false'
  final int timeLimit;
  final int? points;
  final List<CreateAnswerDto> answers;

  CreateQuestionDto({
    required this.questionText,
    this.mediaUrl,
    required this.questionType,
    required this.timeLimit,
    this.points,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
        'questionText': questionText,
        'mediaUrl': mediaUrl,
        'questionType': questionType,
        'timeLimit': timeLimit,
        'points': points,
        'answers': answers.map((a) => a.toJson()).toList(),
      };
}

class CreateQuizDto {
  final String authorId;
  final String title;
  final String? description;
  final String? coverImage;
  final String visibility; // 'public' | 'private'
  final String? themeId;
  final List<CreateQuestionDto> questions;

  CreateQuizDto({
    required this.authorId,
    required this.title,
    this.description,
    this.coverImage,
    required this.visibility,
    this.themeId,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'title': title,
        'description': description,
        'coverImage': coverImage,
        'visibility': visibility,
        'themeId': themeId,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}