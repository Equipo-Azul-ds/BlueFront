// DTOs usados por los use-cases (frontend)
class CreateAnswerDto {
  final String? answerText;
  final String? answerImage;
  final bool isCorrect;

  CreateAnswerDto({this.answerText, this.answerImage, required this.isCorrect});

  Map<String, dynamic> toJson() => {
      // Backend may expect 'answerText' or 'text'. Provide both for compatibility.
      'answerText': answerText,
      'text': answerText,
      'answerImage': answerImage,
      'mediaUrl': answerImage,
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
      // Provide both shapes: 'questionText' (backend examples) and 'text' (internal entities)
      'questionText': questionText,
      'text': questionText,
      'mediaUrl': mediaUrl,
      'questionType': questionType,
      'type': questionType,
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
  final String? status; // 'draft' | 'published'
  final String? category;
  final String? themeId;
  final List<CreateQuestionDto> questions;

  CreateQuizDto({
    required this.authorId,
    required this.title,
    this.description,
    this.coverImage,
    required this.visibility,
    this.status,
    this.category,
    this.themeId,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'title': title,
        'description': description,
        'coverImage': coverImage,
        'visibility': visibility,
        'status': status,
        'category': category,
        'themeId': themeId,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}