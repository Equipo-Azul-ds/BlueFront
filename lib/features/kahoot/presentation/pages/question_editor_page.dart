// lib/features/kahoot/presentation/pages/question_editor_page.dart
import 'dart:io';
 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/dtos/create_quiz_dto.dart';
import '../../application/dtos/create_quiz_dto.dart' show CreateQuestionDto, CreateAnswerDto;
import '../blocs/quiz_editor_bloc.dart';
import '../../../media/presentation/blocs/media_editor_bloc.dart';
import '../../../media/application/dtos/upload_media_dto.dart' show UploadMediaDTO;

class QuestionEditorPage extends StatefulWidget {
  final String quizId;
  final String questionId;

  const QuestionEditorPage({required this.quizId, required this.questionId, Key? key}) : super(key: key);

  @override
  _QuestionEditorPageState createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<QuestionEditorPage> {
  late TextEditingController _textController;
  String? _mediaPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
    final quiz = quizBloc.currentQuiz;
    if (quiz != null) {
      final idx = quiz.questions.indexWhere((qq) => qq.questionId == widget.questionId);
      if (idx != -1) {
        final q = quiz.questions[idx];
        _textController.text = q.text;
        _mediaPath = q.mediaUrl;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadMedia() async {
    final mediaBloc = Provider.of<MediaEditorBloc>(context, listen: false);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      // Lee los bytes del media seleccionado
      final bytes = await File(picked.path).readAsBytes();
      final dto = UploadMediaDTO(
        fileBytes: bytes,
        fileName: picked.name,
        mimeType: _detectMime(picked.path),
        sizeInBytes: bytes.length,
      );

      // Subida via MediaEditorBloc (que usa UploadMediaUseCase)
      final uploaded = await mediaBloc.upload(dto);
      //  Monta el path de la media subida
      final path = (uploaded as dynamic).path as String?;
      if (path != null) {
        setState(() => _mediaPath = path);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archivo subido')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  String _detectMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  CreateQuizDto _buildDtoWithUpdatedQuestion(quiz) {
    // Map quiz.questions -> CreateQuestionDto, reemplaza la editada
    final questionsDtos = quiz.questions.map<CreateQuestionDto>((origQ) {
      if (origQ.questionId != widget.questionId) {
        // map existing question
        final answersDtos = origQ.answers.map<CreateAnswerDto>((a) {
          return CreateAnswerDto(
            answerText: a.text,
            answerImage: a.mediaUrl,
            isCorrect: a.isCorrect,
          );
        }).toList();

        return CreateQuestionDto(
          questionText: origQ.text,
          mediaUrl: origQ.mediaUrl,
          questionType: origQ.type,
          timeLimit: origQ.timeLimit,
          points: origQ.points,
          answers: answersDtos,
        );
      } else {
        // la pregunta editada mantiene las respuestas originales
        final answersDtos = origQ.answers.map<CreateAnswerDto>((a) {
          return CreateAnswerDto(
            answerText: a.text,
            answerImage: a.mediaUrl,
            isCorrect: a.isCorrect,
          );
        }).toList();

        return CreateQuestionDto(
          questionText: _textController.text,
          mediaUrl: _mediaPath,
          questionType: origQ.type,
          timeLimit: origQ.timeLimit,
          points: origQ.points,
          answers: answersDtos,
        );
      }
    }).toList();

    // Construir DTO del Quiz
    return CreateQuizDto(
      authorId: quiz.authorId,
      title: quiz.title,
      description: quiz.description,
      coverImage: quiz.coverImageUrl,
      visibility: quiz.visibility,
      themeId: quiz.themeId,
      questions: questionsDtos,
    );
  }

  Future<void> _save() async {
    final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
    final quiz = quizBloc.currentQuiz;
    if (quiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz no cargado')));
      return;
    }

    final dto = _buildDtoWithUpdatedQuestion(quiz);

    setState(() => _busy = true);
    try {
      await quizBloc.updateQuiz(widget.quizId, dto);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pregunta guardada')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizBloc = Provider.of<QuizEditorBloc>(context);
    final quiz = quizBloc.currentQuiz;
    if (quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor de Pregunta')),
        body: const Center(child: Text('Pregunta o Quiz no encontrados')),
      );
    }

    final idx = quiz.questions.indexWhere((qq) => qq.questionId == widget.questionId);
    if (idx == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor de Pregunta')),
        body: const Center(child: Text('Pregunta o Quiz no encontrados')),
      );
    }


    return Scaffold(
      appBar: AppBar(title: const Text('Editor de Pregunta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'Texto de la pregunta'),
              maxLines: null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _pickAndUploadMedia,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir media'),
                ),
                const SizedBox(width: 12),
                if (_mediaPath != null) Flexible(child: Text('Media: $_mediaPath', overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const CircularProgressIndicator() : const Text('Guardar pregunta'),
            ),
          ],
        ),
      ),
    );
  }
}