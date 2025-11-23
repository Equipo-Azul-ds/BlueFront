import 'package:flutter/foundation.dart';

class Answer{
  final String answerId;
  final String questionId;
  final bool isCorrect;
  final String? text;
  final String? mediaUrl;

  Answer({
    required this.answerId,
    required this.questionId,
    required this.isCorrect,
    this.text,
    this.mediaUrl,
  }):  assert((text == null) != (mediaUrl == null),
             'La respuesta debe tener texto o mediaUrl, pero no ambos ni ninguno');

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      answerId: json['answerId'] ?? json['id'],
      questionId: json['questionId'] ?? json['question_id'],
      isCorrect: json['isCorrect'],
      text: json['text'] ?? json['answerText'] ?? json['answer_text'],
      mediaUrl: json['mediaUrl'] ?? json['mediaId'] ?? json['media_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answerId': answerId,
      'questionId': questionId,
      'isCorrect': isCorrect,
      'text': text,
      'mediaUrl': mediaUrl,
    };
  }
}