import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../blocs/quiz_editor_bloc.dart';
import '../../domain/entities/Question.dart' as Q;
import '../../domain/entities/Answer.dart' as A;
import '../../domain/entities/Quiz.dart';
import '../../../../common_widgets/media_upload.dart' as media;
import '../../application/dtos/create_quiz_dto.dart';

class QuizEditorPage extends StatefulWidget{
  final Quiz? template;
  QuizEditorPage({Key? key, this.template}): super(key: key);

  @override
  _QuizEditorPageState createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage>{
  @override
  void initState(){
    super.initState();
    _questionController = TextEditingController();
    // Si se pasa una plantilla, inicializamos el quiz en el Bloc como una copia lista para edición
    if (widget.template != null){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
        final tpl = widget.template!;
        final now = DateTime.now().microsecondsSinceEpoch;
        // Copiar preguntas y respuestas con ids nuevos para evitar colisiones
        final copiedQuestions = tpl.questions.map((q) {
          final qid = 'q_${now}_${q.questionId}';
          final copiedAnswers = q.answers.map((a) => A.Answer(
            answerId: 'a_${now}_${a.answerId}',
            questionId: qid,
            isCorrect: a.isCorrect,
            text: a.text,
            mediaUrl: a.mediaUrl,
          )).toList();
          return Q.Question(
            questionId: qid,
            quizId: 'quiz_${now}',
            text: q.text,
            mediaUrl: q.mediaUrl,
            type: q.type,
            timeLimit: q.timeLimit,
            points: q.points,
            answers: copiedAnswers,
          );
        }).toList();

            final newQuiz = Quiz(
          quizId: 'quiz_${now}',
          authorId: quizBloc.currentQuiz?.authorId ?? 'author-id-placeholder',
          title: tpl.title,
          description: tpl.description,
          visibility: tpl.visibility,
          themeId: tpl.themeId,
          coverImageUrl: tpl.coverImageUrl,
          createdAt: DateTime.now(),
          questions: copiedQuestions,
        );

            // Si la plantilla trae imagen de portada, la guardamos en el estado local para preview
            if (tpl.coverImageUrl != null) {
              // setState en post-frame para actualizar el widget de MediaUpload
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _coverImagePath = tpl.coverImageUrl);
              });
            }
        quizBloc.setCurrentQuiz(newQuiz);
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
  int _step = 1; //Paso 1: detalles, paso 2: slides
  final _formKey = GlobalKey<FormBuilderState>();
  int _selectedIndex = 0; // índice del slide/pregunta seleccionado

  // Controller para el texto de la pregunta actualmente en edición.
  late TextEditingController _questionController;
  String? _currentEditingQuestionId;

  // Estado temporal para elementos que antes se pasaban directo al BLoC
  String? _coverImagePath;
  String _visibility = 'private';

  Future<void> _saveQuiz() async {
    final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
    // Guardar valores del formulario
    _formKey.currentState?.save();
    final values = _formKey.currentState?.value ?? {};
    final title = values['title'] as String? ?? '';
    final description = values['description'] as String? ?? '';

    // Construir DTO (questions se dejan vacías en esta integración mínima;
    final dto = CreateQuizDto(
      authorId: quizBloc.currentQuiz?.authorId ?? 'author-id-placeholder',
      title: title,
      description: description,
      coverImage: _coverImagePath,
      visibility: _visibility,
      themeId: quizBloc.currentQuiz?.themeId, // mantiene tema si existe
      questions: [], 
    );

    try {
      if (quizBloc.currentQuiz == null) {
        await quizBloc.createQuiz(dto);
      } else {
        await quizBloc.updateQuiz(quizBloc.currentQuiz!.quizId, dto);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz guardado correctamente')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context){
    final quizBloc = Provider.of<QuizEditorBloc>(context);

    final quiz = quizBloc.currentQuiz;
    final slides = quiz?.questions ?? [];
    final selectedQuestion = (slides.isNotEmpty && _selectedIndex < slides.length) ? slides[_selectedIndex] : null;

    // Sincronizar controller cuando cambie la pregunta seleccionada
    if (selectedQuestion != null) {
      if (_currentEditingQuestionId != selectedQuestion.questionId) {
        _currentEditingQuestionId = selectedQuestion.questionId;
        // Actualizar texto del controller sin perder el cursor (asigna directamente)
        _questionController.text = selectedQuestion.text;
      }
    } else {
      _currentEditingQuestionId = null;
      _questionController.text = '';
    }

    if(_step == 1){
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(title: Text('Crear nuevo Quiz'), backgroundColor: AppColor.primary),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth * 0.04),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children:[
                    //Subir imagen -> guardamos localmente la ruta
                    media.MediaUpload(onMediaSelected: (file) {
                      setState(()=> _coverImagePath = file.path);
                    }),
                    SizedBox(height: constraints.maxHeight * 0.02),
                        FormBuilderTextField(
                      name: 'title',
                          initialValue: quiz?.title ?? '',
                      decoration: InputDecoration(
                        labelText:'Titulo',
                        contentPadding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: constraints.maxHeight * 0.015),
                      ),
                      style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                        FormBuilderTextField(
                      name: 'description',
                          initialValue: quiz?.description ?? '',
                      decoration: InputDecoration(
                        labelText:'Descripcion',
                        contentPadding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: constraints.maxHeight * 0.015),
                      ),
                      style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    SwitchListTile(
                      title: Text(
                        'Visible para todos',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                      ),
                      value: _visibility == 'public',
                      onChanged: (val) => setState(()=> _visibility = val ? 'public' : 'private'),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.03),
                    ElevatedButton(
                      onPressed: () => setState(()=>_step = 2),
                      child: Text(
                        'Continuar a preguntas',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, constraints.maxHeight * 0.06),
                        padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.015),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    //Paso 2: Editor de Slides
    return Scaffold(
      appBar: AppBar(
        title: Text('Editando'),
        actions: [
          // Mantengo el icono, pero ahora guarda (create o update)
          IconButton(onPressed: ()=> _saveQuiz(), icon: Icon(Icons.save)),
        ]
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                  children: [
                    // Formulario de slide actual con controles completos
                    Container(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                      decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: selectedQuestion == null
                        ? const Text('Seleccione o cree una pregunta')
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Texto de la pregunta (usando controller persistente para preservar cursor)
                            TextField(
                              controller: _questionController,
                              onChanged: (val) {
                                final q = selectedQuestion;
                                final updated = Q.Question(
                                  questionId: q.questionId,
                                  quizId: q.quizId,
                                  text: val,
                                  mediaUrl: q.mediaUrl,
                                  type: q.type,
                                  timeLimit: q.timeLimit,
                                  points: q.points,
                                  answers: q.answers,
                                );
                                quizBloc.updateQuestionAt(_selectedIndex, updated);
                              },
                              decoration: InputDecoration(hintText: 'Escribe tu pregunta aqui....'),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.01),

                            // Tipo de pregunta y ajustes (timeLimit, points)
                            Row(children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedQuestion.type,
                                  items: ['quiz','true_false'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: (val){
                                    if (val == null) return;
                                    final q = selectedQuestion;
                                    final updated = Q.Question(
                                      questionId: q.questionId,
                                      quizId: q.quizId,
                                      text: q.text,
                                      mediaUrl: q.mediaUrl,
                                      type: val,
                                      timeLimit: q.timeLimit,
                                      points: q.points,
                                      answers: q.answers,
                                    );
                                    quizBloc.updateQuestionAt(_selectedIndex, updated);
                                  },
                                  decoration: InputDecoration(labelText: 'Tipo'),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(width: 100, child: TextFormField(
                                initialValue: selectedQuestion.timeLimit.toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Tiempo(s)'),
                                onChanged: (val){
                                  final q = selectedQuestion;
                                  final parsed = int.tryParse(val) ?? q.timeLimit;
                                  final updated = Q.Question(
                                    questionId: q.questionId,
                                    quizId: q.quizId,
                                    text: q.text,
                                    mediaUrl: q.mediaUrl,
                                    type: q.type,
                                    timeLimit: parsed,
                                    points: q.points,
                                    answers: q.answers,
                                  );
                                  quizBloc.updateQuestionAt(_selectedIndex, updated);
                                },
                              )),
                              SizedBox(width: 8),
                              Container(width: 100, child: TextFormField(
                                initialValue: selectedQuestion.points.toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Puntos'),
                                onChanged: (val){
                                  final q = selectedQuestion;
                                  final parsed = int.tryParse(val) ?? q.points;
                                  final updated = Q.Question(
                                    questionId: q.questionId,
                                    quizId: q.quizId,
                                    text: q.text,
                                    mediaUrl: q.mediaUrl,
                                    type: q.type,
                                    timeLimit: q.timeLimit,
                                    points: parsed,
                                    answers: q.answers,
                                  );
                                  quizBloc.updateQuestionAt(_selectedIndex, updated);
                                },
                              )),
                            ]),
                            SizedBox(height: constraints.maxHeight * 0.01),

                            // Media upload for question
                            media.MediaUpload(onMediaSelected: (file) {
                              final q = selectedQuestion;
                              final updated = Q.Question(
                                questionId: q.questionId,
                                quizId: q.quizId,
                                text: q.text,
                                mediaUrl: file.path,
                                type: q.type,
                                timeLimit: q.timeLimit,
                                points: q.points,
                                answers: q.answers,
                              );
                              quizBloc.updateQuestionAt(_selectedIndex, updated);
                            }),

                            SizedBox(height: constraints.maxHeight * 0.01),

                            // Answers list
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Respuestas', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...selectedQuestion.answers.asMap().entries.map((entry) {
                                  final ans = entry.value;
                                  return Row(children: [
                                    Checkbox(value: ans.isCorrect, onChanged: (v){
                                      final q = selectedQuestion;
                                      final newAnswers = q.answers.map((a) => a.answerId == ans.answerId ? A.Answer(answerId: a.answerId, questionId: a.questionId, isCorrect: v ?? false, text: a.text, mediaUrl: a.mediaUrl) : a).toList();
                                      final updated = Q.Question(
                                        questionId: q.questionId,
                                        quizId: q.quizId,
                                        text: q.text,
                                        mediaUrl: q.mediaUrl,
                                        type: q.type,
                                        timeLimit: q.timeLimit,
                                        points: q.points,
                                        answers: newAnswers,
                                      );
                                      quizBloc.updateQuestionAt(_selectedIndex, updated);
                                    }),
                                    Expanded(child: TextFormField(initialValue: ans.text ?? '', onChanged: (v){
                                      final q = selectedQuestion;
                                      final newAnswers = q.answers.map((a) => a.answerId == ans.answerId ? A.Answer(answerId: a.answerId, questionId: a.questionId, isCorrect: a.isCorrect, text: v, mediaUrl: a.mediaUrl) : a).toList();
                                      final updated = Q.Question(
                                        questionId: q.questionId,
                                        quizId: q.quizId,
                                        text: q.text,
                                        mediaUrl: q.mediaUrl,
                                        type: q.type,
                                        timeLimit: q.timeLimit,
                                        points: q.points,
                                        answers: newAnswers,
                                      );
                                      quizBloc.updateQuestionAt(_selectedIndex, updated);
                                    })),
                                    IconButton(icon: Icon(Icons.delete), onPressed: (){
                                      final q = selectedQuestion;
                                      final newAnswers = q.answers.where((a)=>a.answerId!=ans.answerId).toList();
                                      final updated = Q.Question(
                                        questionId: q.questionId,
                                        quizId: q.quizId,
                                        text: q.text,
                                        mediaUrl: q.mediaUrl,
                                        type: q.type,
                                        timeLimit: q.timeLimit,
                                        points: q.points,
                                        answers: newAnswers,
                                      );
                                      quizBloc.updateQuestionAt(_selectedIndex, updated);
                                    }),
                                  ]);
                                }).toList(),
                                TextButton.icon(onPressed: (){
                                  final q = selectedQuestion;
                                  if (q.type == 'true_false' && q.answers.length >=2) return; // keep two
                                  final now = DateTime.now().microsecondsSinceEpoch;
                                  final newAns = A.Answer(answerId: 'a_$now', questionId: q.questionId, isCorrect: false, text: 'Nueva respuesta');
                                  final updated = Q.Question(
                                    questionId: q.questionId,
                                    quizId: q.quizId,
                                    text: q.text,
                                    mediaUrl: q.mediaUrl,
                                    type: q.type,
                                    timeLimit: q.timeLimit,
                                    points: q.points,
                                    answers: [...q.answers, newAns],
                                  );
                                  quizBloc.updateQuestionAt(_selectedIndex, updated);
                                }, icon: Icon(Icons.add), label: Text('Agregar respuesta')),
                              ],
                            ),

                            // Actions: duplicate or delete question
                            Row(children: [
                              OutlinedButton.icon(onPressed: (){
                                final q = selectedQuestion;
                                final now = DateTime.now().microsecondsSinceEpoch;
                                final copied = Q.Question(
                                  questionId: 'q_copy_$now',
                                  quizId: quizBloc.currentQuiz!.quizId,
                                  text: q.text,
                                  mediaUrl: q.mediaUrl,
                                  type: q.type,
                                  timeLimit: q.timeLimit,
                                  points: q.points,
                                  answers: q.answers.map((a) => A.Answer(answerId: 'a_copy_${now}_${a.answerId}', questionId: 'q_copy_$now', isCorrect: a.isCorrect, text: a.text, mediaUrl: a.mediaUrl)).toList(),
                                );
                                quizBloc.insertQuestionAt(_selectedIndex+1, copied);
                                setState(()=> _selectedIndex = _selectedIndex+1);
                              }, icon: Icon(Icons.copy), label: Text('Duplicar')),
                              SizedBox(width: 8),
                              OutlinedButton.icon(onPressed: (){
                                quizBloc.removeQuestionAt(_selectedIndex);
                                if (_selectedIndex > 0) setState(()=> _selectedIndex = _selectedIndex-1);
                              }, icon: Icon(Icons.delete), label: Text('Eliminar')),
                            ])
                          ],
                        ),
                    ),
                  ],
                ),
              ),
              //Barra inferior de los slides
              Container(
                height: constraints.maxHeight * 0.1,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (slides.length) + 1,
                  itemBuilder: (contact, index){
                    if(index == slides.length){
                      return IconButton(
                        onPressed: (){
                          if (quizBloc.currentQuiz == null){
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guarda el quiz primero (Paso 1)')));
                            return;
                          }
                          // Crear pregunta mínima válida localmente y seleccionar
                          final now = DateTime.now().microsecondsSinceEpoch;
                          final qid = 'q_$now';
                          final a1 = A.Answer(answerId: 'a1_$now', questionId: qid, isCorrect: true, text: 'Respuesta 1');
                          final a2 = A.Answer(answerId: 'a2_$now', questionId: qid, isCorrect: false, text: 'Respuesta 2');
                          final newQ = Q.Question(
                            questionId: qid,
                            quizId: quizBloc.currentQuiz!.quizId,
                            text: 'Nueva pregunta',
                            mediaUrl: null,
                            type: 'quiz',
                            timeLimit: 30,
                            points: 100,
                            answers: [a1, a2],
                          );

                          quizBloc.insertQuestionAt(quizBloc.currentQuiz!.questions.length, newQ);
                          setState(()=> _selectedIndex = quizBloc.currentQuiz!.questions.length - 1);
                        },
                        icon: Icon(Icons.add),
                        iconSize: constraints.maxWidth * 0.06);
                    }
                    final isSelected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: ()=> setState(()=> _selectedIndex = index),
                      child: Container(
                        width: constraints.maxWidth * 0.1,
                        margin: EdgeInsets.all(constraints.maxWidth * 0.02),
                        decoration: BoxDecoration(color: isSelected ? AppColor.primary.withOpacity(0.15) : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text('Q${index + 1}', style: TextStyle(fontSize: constraints.maxWidth * 0.035))),
                      ),
                    );
                  }
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}