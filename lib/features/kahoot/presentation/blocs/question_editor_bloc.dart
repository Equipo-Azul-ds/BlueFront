import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/Quiz.dart';
import '../../domain/entities/Question.dart' as Q;
import '../../domain/entities/Answer.dart' as A;
import '../../application/dtos/create_quiz_dto.dart';
import '../../application/dtos/create_quiz_dto.dart' show CreateQuestionDto, CreateAnswerDto;
import '../blocs/quiz_editor_bloc.dart';
import '../../../media/presentation/blocs/media_editor_bloc.dart';
import '../../../media/application/dtos/upload_media_dto.dart';

/// Bloc para editar una sola pregunta (Question). Mantiene estado local
/// y al guardar reconstrulle el DTO del Quiz y llama a QuizEditorBloc.updateQuiz.
class QuestionEditorBloc extends ChangeNotifier {
  final QuizEditorBloc quizBloc;
  final MediaEditorBloc mediaBloc;

  // Identificadores
  String? quizId;
  String? questionId;

  // Estado de edición local
  String text = '';
  String? mediaUrl;
  List<_EditableAnswer> answers = [];

  bool isLoading = false;
  String? errorMessage;

  QuestionEditorBloc({required this.quizBloc, required this.mediaBloc});

  // Inicializa con los ids y carga la pregunta desde quizBloc.currentQuiz
  void init({required String quizId, required String questionId}) {
    this.quizId = quizId;
    this.questionId = questionId;
    _loadFromQuiz();
  }

  void _loadFromQuiz() {
    final quiz = quizBloc.currentQuiz;
    if (quiz == null || questionId == null) return;

    final q = quiz.questions.firstWhere((qq) => qq.questionId == questionId, orElse: () => null as dynamic);
    if (q == null) return;

    text = q.text ?? '';
    mediaUrl = q.mediaUrl;
    answers = q.answers.map((a) => _EditableAnswer(
      answerId: a.answerId,
      isCorrect: a.isCorrect,
      text: a.text,
      mediaUrl: a.mediaUrl,
    )).toList();

    notifyListeners();
  }

  // Mutadores locales
  void setText(String newText) {
    text = newText;
    notifyListeners();
  }

  void setMediaUrl(String? url) {
    mediaUrl = url;
    notifyListeners();
  }

  void addTextAnswer(String id, String answerText, {bool isCorrect = false}) {
    answers.add(_EditableAnswer(answerId: id, isCorrect: isCorrect, text: answerText));
    notifyListeners();
  }

  void addMediaAnswer(String id, String mediaUrl, {bool isCorrect = false}) {
    answers.add(_EditableAnswer(answerId: id, isCorrect: isCorrect, mediaUrl: mediaUrl));
    notifyListeners();
  }

  void updateAnswerText(String answerId, String newText) {
    final idx = answers.indexWhere((a) => a.answerId == answerId);
    if (idx == -1) return;
    answers[idx] = answers[idx].copyWith(text: newText, mediaUrl: null);
    notifyListeners();
  }

  void updateAnswerMedia(String answerId, String media) {
    final idx = answers.indexWhere((a) => a.answerId == answerId);
    if (idx == -1) return;
    answers[idx] = answers[idx].copyWith(mediaUrl: media, text: null);
    notifyListeners();
  }

  void setAnswerCorrect(String answerId, bool isCorrect) {
    final idx = answers.indexWhere((a) => a.answerId == answerId);
    if (idx == -1) return;
    answers[idx] = answers[idx].copyWith(isCorrect: isCorrect);
    notifyListeners();
  }

  void removeAnswer(String answerId) {
    answers.removeWhere((a) => a.answerId == answerId);
    notifyListeners();
  }

  // Upload de media usando MediaEditorBloc (helper para XFile)
  Future<String?> uploadMediaFromPicker() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final dto = UploadMediaDTO(
      fileBytes: bytes,
      fileName: picked.name,
      mimeType: _detectMime(picked.path),
      sizeInBytes: bytes.length,
    );

    _startLoading();
    try {
      final uploaded = await mediaBloc.upload(dto);
      final path = (uploaded as dynamic).path as String?;
      mediaUrl = path;
      notifyListeners();
      return path;
    } catch (e) {
      errorMessage = 'Error al subir media: $e';
      notifyListeners();
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // Guarda la pregunta: reconstruye CreateQuizDto y llama a quizBloc.updateQuiz
  Future<void> save() async {
    if (quizId == null || questionId == null) {
      throw StateError('QuestionEditorBloc no inicializado con quizId/questionId');
    }
    final quiz = quizBloc.currentQuiz;
    if (quiz == null) throw StateError('Quiz no cargado');

    _startLoading();
    try {
      // Reconstruir lista de CreateQuestionDto con la pregunta editada reemplazada
      final questionsDtos = quiz.questions.map<CreateQuestionDto>((origQ) {
        if (origQ.questionId != questionId) {
          // convertir la pregunta existente a DTO
          final answersDtos = origQ.answers.map((a) => CreateAnswerDto(
            answerText: a.text,
            answerImage: a.mediaUrl,
            isCorrect: a.isCorrect,
          )).toList();

          return CreateQuestionDto(
            questionText: origQ.text,
            mediaUrl: origQ.mediaUrl,
            questionType: origQ.type,
            timeLimit: origQ.timeLimit,
            points: origQ.points,
            answers: answersDtos,
          );
        } else {
          // la pregunta editada
          final answersDtos = answers.map((a) => CreateAnswerDto(
            answerText: a.text,
            answerImage: a.mediaUrl,
            isCorrect: a.isCorrect,
          )).toList();

          return CreateQuestionDto(
            questionText: text,
            mediaUrl: mediaUrl,
            questionType: origQ.type,
            timeLimit: origQ.timeLimit,
            points: origQ.points,
            answers: answersDtos,
          );
        }
      }).toList();

      // Construir DTO del Quiz
      final dto = CreateQuizDto(
        authorId: quiz.authorId,
        title: quiz.title,
        description: quiz.description,
        coverImage: quiz.coverImageUrl,
        visibility: quiz.visibility,
        themeId: quiz.themeId,
        questions: questionsDtos,
      );

      // Llamar al usecase del Quiz (a través del bloc)
      await quizBloc.updateQuiz(quizId!, dto);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Error al guardar pregunta: $e';
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // Helpers privados
  void _startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void _stopLoading() {
    isLoading = false;
    notifyListeners();
  }

  String _detectMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }
}

/// Helper mutable-inmutable para respuestas locales
class _EditableAnswer {
  final String answerId;
  final bool isCorrect;
  final String? text;
  final String? mediaUrl;

  _EditableAnswer({
    required this.answerId,
    required this.isCorrect,
    this.text,
    this.mediaUrl,
  });

  _EditableAnswer copyWith({String? answerId, bool? isCorrect, String? text, String? mediaUrl}) {
    return _EditableAnswer(
      answerId: answerId ?? this.answerId,
      isCorrect: isCorrect ?? this.isCorrect,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}