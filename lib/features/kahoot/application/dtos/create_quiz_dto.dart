// DTOs usados por los use-cases (frontend)
class CreateAnswerDto {
  final String? answerText;
  final String? answerImage;
  final bool isCorrect;

  CreateAnswerDto({this.answerText, this.answerImage, required this.isCorrect});

  Map<String, dynamic> toJson() => {
      // El backend puede esperar 'answerText' o 'text'
      'answerText': answerText,
      'text': answerText,
      // Mantener nombres del contrato: 'media' y 'mediaId'. Guardar URL en mediaId según requisito.
      'answerImage': answerImage, // compat
      'media': answerImage,
      'mediaId': answerImage,
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
      // Proporciona ambas formas: 'questionText' (ejemplos del backend) y 'text' (entidades internas)
      'questionText': questionText,
      'text': questionText,
      // Mantener nombres del contrato: 'media' y 'mediaId'. Guardar URL en mediaId según requisito.
      'media': mediaUrl,
      'mediaId': mediaUrl,
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
      'coverImageId': coverImage,
        'visibility': visibility,
        'status': status,
        'category': category,
        'themeId': themeId,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}