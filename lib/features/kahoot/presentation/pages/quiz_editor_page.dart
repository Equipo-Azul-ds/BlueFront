import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../media/presentation/blocs/media_editor_bloc.dart';
import '../blocs/quiz_editor_bloc.dart';
import '../../domain/entities/Question.dart' as Q;
import '../../domain/entities/Answer.dart' as A;
import '../../domain/entities/Quiz.dart';
 
import '../../../../common_widgets/media_upload.dart' as media;
import '../../application/dtos/create_quiz_dto.dart';
import 'package:uuid/uuid.dart';

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
            quizId: '',
            text: q.text,
            mediaUrl: q.mediaUrl,
            type: q.type,
            timeLimit: q.timeLimit,
            points: q.points,
            answers: copiedAnswers,
          );
        }).toList();

        const defaultTestAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
        final newQuiz = Quiz(
          quizId: Uuid().v4(),
          authorId: (quizBloc.currentQuiz?.authorId == null || (quizBloc.currentQuiz!.authorId.contains('placeholder'))) ? defaultTestAuthorId : quizBloc.currentQuiz!.authorId,
          title: tpl.title,
          description: tpl.description,
          visibility: tpl.visibility,
          status: tpl.status,
          category: tpl.category,
          themeId: tpl.themeId,
          coverImageUrl: tpl.coverImageUrl,
          isLocal: true,
          createdAt: DateTime.now(),
          questions: copiedQuestions,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Inicializar controles UI con valores de la plantilla
          setState(() {
            _coverImagePath = tpl.coverImageUrl;
            _visibility = tpl.visibility;
            _status = tpl.status ?? 'draft';
            _category = tpl.category ?? 'Tecnología';
            _selectedThemeId = tpl.themeId;
          });
          quizBloc.setCurrentQuiz(newQuiz);
        });
      });
    } else {
      // Si no hay plantilla, sólo inicializar un quiz local vacío si el BLoC
      // no tiene ya un `currentQuiz` (por ejemplo cuando venimos del flujo
      // de edición y ya cargamos el quiz remoto). Esto evita sobreescribir
      // la entidad cargada que debe editarse.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
        if (quizBloc.currentQuiz != null) return; // ya hay un quiz cargado -> no sobrescribir
        const defaultTestAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
        final newQuiz = Quiz(
          quizId: '',
          authorId: (quizBloc.currentQuiz?.authorId == null || (quizBloc.currentQuiz!.authorId.contains('placeholder'))) ? defaultTestAuthorId : quizBloc.currentQuiz!.authorId,
          title: '',
          description: '',
          visibility: 'private',
          status: 'draft',
          category: 'Tecnología',
          themeId: _selectedThemeId ?? defaultTestAuthorId,
          coverImageUrl: null,
          isLocal: true,
          createdAt: DateTime.now(),
          questions: [],
        );

        if (!mounted) return;
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

  // Inline answer editing state: set of answerIds currently being edited
  final Set<String> _editingAnswerIds = {};
  // store original text when start editing to allow cancel
  final Map<String, String> _editingInitialValues = {};

  // Estado temporal para elementos que antes se pasaban directo al BLoC
  String? _coverImagePath;
  Uint8List? _coverImageBytes;
  String _visibility = 'private';
  String _status = 'draft';
  String _category = 'Tecnología';
  // Lista local de temas disponibles para selección en la UI
  final List<Map<String, String>> _availableThemes = [
    {'id': 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4', 'name': 'Estándar', 'color': '7B1FA2'},
    {'id': 'd2ad3a12-4f1b-4c3e-9f2a-1a2b3c4d5e6f', 'name': 'Summer', 'color': '00BFA5'},
    {'id': 'a3b9c8d7-1234-4ef0-9abc-0d1e2f3a4b5c', 'name': 'Spring', 'color': 'FFCDD2'},
    {'id': 'b4c2d1e0-5678-49ab-8cde-9f0a1b2c3d4e', 'name': 'Winter', 'color': '90CAF9'},
    {'id': 'c5d3e2f1-9abc-4def-8a1b-2c3d4e5f6a7b', 'name': 'Autumn', 'color': 'FFB74D'},
    {'id': 'e6f4a3b2-0f1e-4a5b-9cde-3b4c5d6e7f8a', 'name': 'Support Ukraine', 'color': 'FFD54F'},
  ];
  String? _selectedThemeId;
  
  // Devuelve el color asociado a un themeId; si no hay match devuelve null
  Color? _colorForTheme(String? id) {
    if (id == null) return null;
    try {
      final t = _availableThemes.firstWhere((e) => e['id'] == id, orElse: () => {} as Map<String, String>);
      if (t.isEmpty) return null;
      return Color(int.parse('0xFF${t['color']}'));
    } catch (_) {
      return null;
    }
  }
  

  Future<void> _saveQuiz() async {
    final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
    // Try to read form values if the form is present (step 1). If the form
    // is not mounted (we're in step 2), fall back to the values already stored
    // in `quizBloc.currentQuiz` so saving still works.
    String title = '';
    String description = '';
    // Attempt to save/validate only if the form exists in the tree
    if (_formKey.currentState != null) {
      _formKey.currentState?.save();
      final valid = _formKey.currentState?.validate() ?? true;
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Corrige los errores del formulario antes de guardar')));
        return;
      }
      final values = _formKey.currentState?.value ?? {};
      title = values['title'] as String? ?? '';
      description = values['description'] as String? ?? '';
    }

    // If form didn't provide values (e.g., user is on step 2), use currentQuiz fields
    if (title.isEmpty) title = quizBloc.currentQuiz?.title ?? '';
    if (description.isEmpty) description = quizBloc.currentQuiz?.description ?? '';

    // Normalize title (trim) and refuse to save empty titles early with a clear UI message.
    title = title.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El título no puede estar vacío')));
      return;
    }

    // Construir DTO (questions se dejan vacías en esta integración mínima;
    // Mapear preguntas y respuestas desde el currentQuiz si existen
    List<CreateQuestionDto> mappedQuestions = [];
    if (quizBloc.currentQuiz != null && quizBloc.currentQuiz!.questions.isNotEmpty) {
      final allowedPoints = <int>{0, 1000, 2000};
      int _normalizePoints(int p) => allowedPoints.contains(p) ? p : 1000;

      mappedQuestions = quizBloc.currentQuiz!.questions.map((q) {
        final answers = q.answers.map((a) => CreateAnswerDto(
          answerText: a.text,
          answerImage: a.mediaUrl,
          isCorrect: a.isCorrect,
        )).toList();
        return CreateQuestionDto(
          questionText: q.text,
          mediaUrl: q.mediaUrl,
          questionType: q.type,
          timeLimit: q.timeLimit,
          points: _normalizePoints(q.points),
          answers: answers,
        );
      }).toList();
    }

    final dto = CreateQuizDto(
      // Use a default author id for testing when currentQuiz has no valid author
      authorId: (() {
        const defaultTestAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
        final aid = quizBloc.currentQuiz?.authorId ?? '';
        if (aid.isEmpty || aid.contains('placeholder')) return defaultTestAuthorId;
        return aid;
      })(),
      title: title,
      description: description,
      coverImage: quizBloc.currentQuiz?.coverImageUrl ?? _coverImagePath,
      visibility: quizBloc.currentQuiz?.visibility ?? _visibility,
      status: quizBloc.currentQuiz?.status ?? _status,
      category: quizBloc.currentQuiz?.category ?? _category,
      themeId: quizBloc.currentQuiz?.themeId ?? _selectedThemeId, // mantiene tema si existe
      questions: mappedQuestions,
    );

    try {
      // Decide create vs update based on whether the current quiz is a
      // local (unsaved/duplicated/template) instance. Local quizzes should
      // be POSTed (create). Persisted quizzes (isLocal == false) are PUT.
      if (quizBloc.currentQuiz == null || quizBloc.currentQuiz!.isLocal == true) {
        print('[editor] performing CREATE (currentQuiz is local or null)');
        try {
          // Debug: log DTO contents to ensure fields from the form are captured
          print('[editor][DEBUG] DTO title raw: "${dto.title}" length=${dto.title.length}');
          print('[editor][DEBUG] DTO preview JSON: ${dto.toJson()}');
        } catch (_) {}
        await quizBloc.createQuiz(dto);
        if (quizBloc.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: ${quizBloc.errorMessage}')));
          return;
        }
      } else {
        print('[editor] performing UPDATE for id=${quizBloc.currentQuiz!.quizId}');
        try {
          // Always log DTO for updates as well — helps debug title/fields sent to backend.
          try {
            print('[editor][DEBUG] DTO title raw: "${dto.title}" length=${dto.title.length}');
            print('[editor][DEBUG] DTO preview JSON: ${dto.toJson()}');
          } catch (_) {}

          await quizBloc.updateQuiz(quizBloc.currentQuiz!.quizId, dto);
          if (quizBloc.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: ${quizBloc.errorMessage}')));
            return;
          }
        } catch (e) {
          // If update fails with a validation message coming from usecase/repo, surface it
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
          return;
        }
      }
      // Prefer not to call backend with placeholder author id. If we have a valid UUID v4
      // authorId, refresh the list; otherwise pass the created quiz to the dashboard via
      // route arguments so it can be shown immediately without hitting the API.
      final created = quizBloc.currentQuiz;
      final authorIdCandidate = created?.authorId ?? '';
      const defaultTestAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
      // Try to refresh user quizzes for a good UX. If the provided authorId
      // is missing or is a placeholder, retry/load using the default test
      // author id to avoid backend validation errors during testing.
      var loaded = false;
      if (authorIdCandidate.isNotEmpty && !authorIdCandidate.contains('placeholder')) {
        try {
          await quizBloc.loadUserQuizzes(authorIdCandidate);
          loaded = true;
        } catch (e) {
          print('[editor] loadUserQuizzes failed for author=$authorIdCandidate -> $e');
        }
      }

      if (!loaded) {
        try {
          print('[editor] attempting loadUserQuizzes with default test author id');
          await quizBloc.loadUserQuizzes(defaultTestAuthorId);
          loaded = true;
        } catch (e) {
          print('[editor] loadUserQuizzes with default author failed -> $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz guardado correctamente')));
      print('[editor] save completed; created=${created != null ? created.quizId + " / " + created.title : "<null>"} loaded=$loaded authorCandidate=$authorIdCandidate');
      // Normalize the quiz we pass to the dashboard: do not mark as local
      // when returning via navigation after a successful save.
      Quiz? nonLocalCreated;
      if (created != null) {
        nonLocalCreated = Quiz(
          quizId: created.quizId,
          authorId: created.authorId,
          title: created.title,
          description: created.description,
          visibility: created.visibility,
          status: created.status,
          category: created.category,
          themeId: created.themeId,
          templateId: created.templateId,
          coverImageUrl: created.coverImageUrl,
          isLocal: false,
          createdAt: created.createdAt,
          questions: created.questions,
        );
        // Ensure bloc also reflects non-local state when possible
        quizBloc.setCurrentQuiz(nonLocalCreated);
      }
      // If we couldn't load the remote list, pass the created quiz so dashboard
      // can show it immediately; otherwise navigate normally.
      if (loaded) {
        // Ensure the created quiz is present in the loaded list; if backend
        // didn't include it, insert it locally so Dashboard shows it.
        if (created != null) {
          quizBloc.userQuizzes ??= [];
          final exists = quizBloc.userQuizzes!.any((q) => q.quizId == created.quizId || (q.title == created.title && q.createdAt.toIso8601String() == created.createdAt.toIso8601String()));
          if (!exists) {
            // If the created has empty quizId, keep it as local (isLocal true)
            final toInsert = created.quizId.isEmpty
                ? Quiz(
                    quizId: created.quizId,
                    authorId: created.authorId,
                    title: created.title,
                    description: created.description,
                    visibility: created.visibility,
                    status: created.status,
                    category: created.category,
                    themeId: created.themeId,
                    templateId: created.templateId,
                    coverImageUrl: created.coverImageUrl,
                    isLocal: true,
                    createdAt: created.createdAt,
                    questions: created.questions,
                  )
                : created;
            // If we have normalized nonLocalCreated, insert that so dashboard shows
            // a non-local card for the newly created quiz.
            // Always insert a fresh instance into the list to avoid later
            // in-editor mutations modifying the list item by reference.
            final chosen = (nonLocalCreated != null && !nonLocalCreated.quizId.isEmpty) ? nonLocalCreated : toInsert;
            final localId = (chosen.quizId.isEmpty) ? Uuid().v4() : chosen.quizId;
            final toStore = Quiz(
              quizId: localId,
              authorId: chosen.authorId,
              title: chosen.title,
              description: chosen.description,
              visibility: chosen.visibility,
              status: chosen.status,
              category: chosen.category,
              themeId: chosen.themeId,
              templateId: chosen.templateId,
              coverImageUrl: chosen.coverImageUrl,
              isLocal: chosen.isLocal,
              createdAt: chosen.createdAt,
              questions: List.from(chosen.questions),
            );
            quizBloc.userQuizzes!.insert(0, toStore);
            print('[editor] inserted created quiz into userQuizzes after load: id=${toStore.quizId} title=${toStore.title} isLocal=${toStore.isLocal}');
          }
        }
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false, arguments: (nonLocalCreated != null && nonLocalCreated.quizId.isNotEmpty) ? nonLocalCreated : created);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  // (Template preview and apply removed; use TemplateSelectorPage instead)

  @override
  Widget build(BuildContext context){
    final quizBloc = Provider.of<QuizEditorBloc>(context);

    final quiz = quizBloc.currentQuiz;
    final slides = quiz?.questions ?? [];
    final selectedQuestion = (slides.isNotEmpty && _selectedIndex < slides.length) ? slides[_selectedIndex] : null;

    // Asegurar que el selector local de tema tenga el valor actual del quiz al construir
    _selectedThemeId ??= quiz?.themeId;

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
        backgroundColor: _colorForTheme(_selectedThemeId) ?? AppColor.background,
        appBar: AppBar(title: Text('Crear nuevo Quiz'), backgroundColor: AppColor.primary),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth * 0.04),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children:[
                    //Subir imagen -> mostramos vista previa local, subimos al backend y guardamos el mediaId o path
                    media.MediaUpload(
                      previewBytes: _coverImageBytes,
                      previewUrl: (_coverImagePath != null && (_coverImagePath!.startsWith('http'))) ? _coverImagePath : null,
                      onMediaSelected: (file) async {
                        final mediaBloc = Provider.of<MediaEditorBloc>(context, listen: false);
                        try {
                          final bytes = await file.readAsBytes();
                          setState((){
                            _coverImageBytes = bytes; // show immediate local preview
                          });

                          final uploaded = await mediaBloc.uploadFromXFile(file);
                          // uploaded may contain id and/or path/url. Prefer path if it's a URL.
                          final uploadedMap = uploaded as dynamic;
                          final returnedPath = (uploadedMap.path ?? uploadedMap.url ?? uploadedMap.previewPath) as String?;
                          final returnedId = (uploadedMap.id ?? uploadedMap.mediaId) as String?;

                          if (returnedPath != null && returnedPath.startsWith('http')) {
                            // backend returned a usable public URL
                            setState((){
                              _coverImagePath = returnedPath;
                              _coverImageBytes = null; // use network image
                            });
                            if (quizBloc.currentQuiz != null) {
                              quizBloc.currentQuiz!.coverImageUrl = returnedPath;
                              quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                            }
                          } else if (returnedId != null && returnedId.isNotEmpty) {
                            // backend returned only an id — store it and keep local preview
                            setState(()=> _coverImagePath = returnedId);
                            if (quizBloc.currentQuiz != null) {
                              quizBloc.currentQuiz!.coverImageUrl = returnedId;
                              quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                            }
                            // Optionally try to fetch stored bytes from server (not necessary for immediate preview)
                          } else if (returnedPath != null) {
                            setState(()=> _coverImagePath = returnedPath);
                            if (quizBloc.currentQuiz != null) {
                              quizBloc.currentQuiz!.coverImageUrl = returnedPath;
                              quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                            }
                          }

                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagen subida')));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error subiendo imagen: $e')));
                        }
                      }
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                        FormBuilderTextField(
                          name: 'title',
                          initialValue: quiz?.title ?? '',
                          decoration: InputDecoration(
                            labelText:'Titulo',
                            contentPadding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: constraints.maxHeight * 0.015),
                          ),
                          style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                          validator: (val) {
                            final s = (val ?? '').toString().trim();
                            if (s.isEmpty) return 'El título es obligatorio';
                            if (s.length > 95) return 'El título no puede tener más de 95 caracteres';
                            return null;
                          },
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
                    // Selector de Tema (Tema visual del Kahoot)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tema', style: TextStyle(fontSize: constraints.maxWidth * 0.04, fontWeight: FontWeight.w600)),
                        SizedBox(height: constraints.maxHeight * 0.01),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableThemes.map((t) {
                            final tid = t['id']!;
                            final name = t['name']!;
                            final colorHex = t['color']!;
                            final selected = _selectedThemeId == tid;
                            return GestureDetector(
                              onTap: () async {
                                // Mostrar previsualización y preguntar si desea aplicar este tema
                                final picked = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => ThemePreviewDialog(
                                    themeName: name,
                                    color: Color(int.parse('0xFF$colorHex')),
                                  ),
                                );
                                if (picked == true) {
                                  setState(() {
                                    _selectedThemeId = tid;
                                  });
                                  if (quizBloc.currentQuiz != null) {
                                    quizBloc.currentQuiz!.themeId = tid;
                                    quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                                  }
                                }
                              },
                              child: Container(
                                width: constraints.maxWidth * 0.28,
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Color(int.parse('0xFF$colorHex')),
                                  borderRadius: BorderRadius.circular(8),
                                  border: selected ? Border.all(color: AppColor.primary, width: 3) : null,
                                ),
                                child: Center(child: Text(name, style: TextStyle(color: Colors.white))),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.02),
                      ],
                    ),
                    // Estado (status) y categoria del quiz
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          items: ['draft','published'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) {
                            final val = v ?? 'draft';
                            setState(()=> _status = val);
                            // Propagar al BLoC para que saveCurrentQuiz use el valor seleccionado
                            if (quizBloc.currentQuiz != null) {
                              quizBloc.currentQuiz!.status = _status;
                              quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                            }
                          },
                          decoration: InputDecoration(labelText: 'Estado'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          items: ['Tecnología','Educación','General'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) {
                            final val = v ?? 'Tecnología';
                            setState(()=> _category = val);
                            if (quizBloc.currentQuiz != null) {
                              quizBloc.currentQuiz!.category = _category;
                              quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                            }
                          },
                          decoration: InputDecoration(labelText: 'Categoría'),
                        ),
                      ),
                    ]),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    SwitchListTile(
                      title: Text(
                        'Visible para todos',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                      ),
                      value: _visibility == 'public',
                      onChanged: (val) {
                        final v = val ? 'public' : 'private';
                        setState(()=> _visibility = v);
                        if (quizBloc.currentQuiz != null) {
                          quizBloc.currentQuiz!.visibility = _visibility;
                          quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                        }
                      },
                    ),
                    SizedBox(height: constraints.maxHeight * 0.03),
                    ElevatedButton(
                      onPressed: () {
                        // Save form values and propagate to currentQuiz before moving to questions
                        _formKey.currentState?.save();
                        final values = _formKey.currentState?.value ?? {};
                        final titleVal = values['title'] as String? ?? '';
                        final descriptionVal = values['description'] as String? ?? '';
                        // Update the in-memory quiz so subsequent saveCurrentQuiz uses updated values
                        if (quizBloc.currentQuiz != null) {
                          quizBloc.currentQuiz!.title = titleVal;
                          quizBloc.currentQuiz!.description = descriptionVal;
                          quizBloc.currentQuiz!.visibility = _visibility;
                          quizBloc.currentQuiz!.status = _status;
                          quizBloc.currentQuiz!.category = _category;
                          quizBloc.currentQuiz!.coverImageUrl = _coverImagePath;
                          quizBloc.currentQuiz!.themeId = (_selectedThemeId ?? quizBloc.currentQuiz!.themeId).toString();
                          quizBloc.setCurrentQuiz(quizBloc.currentQuiz!);
                        }
                        setState(()=>_step = 2);
                      },
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
      backgroundColor: _colorForTheme(_selectedThemeId) ?? AppColor.background,
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
                    // Strip de slides: tarjetas grandes tipo Kahoot. Tocar selecciona para editar.
                    if (slides.isNotEmpty)
                      Container(
                        height: constraints.maxHeight * 0.18,
                        margin: EdgeInsets.only(bottom: constraints.maxHeight * 0.02),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: slides.length,
                          itemBuilder: (_, idx) {
                            final s = slides[idx];
                            final selected = idx == _selectedIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedIndex = idx),
                              child: Container(
                                width: constraints.maxWidth * 0.38,
                                margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.02),
                                child: Card(
                                  color: selected ? AppColor.primary.withOpacity(0.12) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: selected ? BorderSide(color: AppColor.primary, width: 2) : BorderSide(color: Colors.grey.shade200)),
                                  child: Padding(
                                    padding: EdgeInsets.all(constraints.maxWidth * 0.03),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s.text,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: constraints.maxWidth * 0.035, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        SizedBox(height: constraints.maxHeight * 0.01),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${s.answers.length} respuestas', style: TextStyle(fontSize: constraints.maxWidth * 0.03, color: Colors.grey[700])),
                                            Icon(Icons.edit, size: constraints.maxWidth * 0.05, color: selected ? AppColor.primary : Colors.grey)
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Formulario de slide actual con controles completos
                    Container(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                      decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: selectedQuestion == null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Seleccione o cree una pregunta', style: TextStyle(fontSize: constraints.maxWidth * 0.045)),
                            SizedBox(height: constraints.maxHeight * 0.02),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (quizBloc.currentQuiz == null){
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guarda el quiz primero (Paso 1)')));
                                  return;
                                }
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
                                  points: 1000,
                                  answers: [a1, a2],
                                );

                                // Insert locally only; do not persist until the user saves the whole quiz
                                quizBloc.insertQuestionAt(quizBloc.currentQuiz!.questions.length, newQ);
                                setState(()=> _selectedIndex = quizBloc.currentQuiz!.questions.length - 1);

                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pregunta creada (local). Guarda el quiz para persistirla')));
                              },
                              icon: Icon(Icons.add),
                              label: Text('Crear pregunta'),
                            )
                          ],
                        )
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
                              Container(
                                width: 100,
                                child: DropdownButtonFormField<int>(
                                  value: selectedQuestion.points,
                                  decoration: InputDecoration(labelText: 'Puntos'),
                                  items: (<int>{selectedQuestion.points, 0, 1000, 2000}).toList().map((p) => DropdownMenuItem(value: p, child: Text(p.toString()))).toList(),
                                  onChanged: (val){
                                    if (val == null) return;
                                    final q = selectedQuestion;
                                    final updated = Q.Question(
                                      questionId: q.questionId,
                                      quizId: q.quizId,
                                      text: q.text,
                                      mediaUrl: q.mediaUrl,
                                      type: q.type,
                                      timeLimit: q.timeLimit,
                                      points: val,
                                      answers: q.answers,
                                    );
                                    quizBloc.updateQuestionAt(_selectedIndex, updated);
                                  },
                                ),
                              ),
                            ]),
                            SizedBox(height: constraints.maxHeight * 0.01),

                            // Media upload for question
                            media.MediaUpload(onMediaSelected: (file) async {
                              final q = selectedQuestion;
                              final mediaBloc = Provider.of<MediaEditorBloc>(context, listen: false);
                              try {
                                final uploaded = await mediaBloc.uploadFromXFile(file);
                                final mediaId = (uploaded as dynamic).id ?? (uploaded as dynamic).mediaId ?? file.path;
                                final updated = Q.Question(
                                  questionId: q.questionId,
                                  quizId: q.quizId,
                                  text: q.text,
                                  // Guardamos el mediaId devuelto por el backend en la propiedad mediaUrl
                                  mediaUrl: mediaId,
                                  type: q.type,
                                  timeLimit: q.timeLimit,
                                  points: q.points,
                                  answers: q.answers,
                                );
                                quizBloc.updateQuestionAt(_selectedIndex, updated);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media subida para la pregunta')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error subiendo media: $e')));
                              }
                            }),

                            SizedBox(height: constraints.maxHeight * 0.01),

                            // Answers list (visual, wider tiles + inline edit)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Respuestas', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: constraints.maxHeight * 0.01),

                                // True/False tiles (editable inline)
                                if (selectedQuestion.type == 'true_false')
                                  Builder(builder: (_) {
                                    final q = selectedQuestion;
                                    final now = DateTime.now().microsecondsSinceEpoch;
                                    final trueAns = q.answers.isNotEmpty
                                        ? q.answers[0]
                                        : A.Answer(answerId: 'a_tf_true_$now', questionId: q.questionId, isCorrect: true, text: 'Verdadero');
                                    final falseAns = q.answers.length > 1
                                        ? q.answers[1]
                                        : A.Answer(answerId: 'a_tf_false_$now', questionId: q.questionId, isCorrect: false, text: 'Falso');

                                    Widget buildTile(A.Answer ans, Color bg, EdgeInsets margin) {
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: (){
                                            // don't toggle correctness while editing
                                            if (_editingAnswerIds.contains(ans.answerId)) return;
                                            // Mark the tapped tile as correct, the other as incorrect
                                            final updatedTrue = A.Answer(
                                              answerId: trueAns.answerId,
                                              questionId: trueAns.questionId,
                                              isCorrect: ans.answerId == trueAns.answerId,
                                              text: trueAns.text,
                                              mediaUrl: trueAns.mediaUrl,
                                            );
                                            final updatedFalse = A.Answer(
                                              answerId: falseAns.answerId,
                                              questionId: falseAns.questionId,
                                              isCorrect: ans.answerId == falseAns.answerId,
                                              text: falseAns.text,
                                              mediaUrl: falseAns.mediaUrl,
                                            );
                                            final qUpdated = Q.Question(
                                              questionId: selectedQuestion.questionId,
                                              quizId: selectedQuestion.quizId,
                                              text: selectedQuestion.text,
                                              mediaUrl: selectedQuestion.mediaUrl,
                                              type: selectedQuestion.type,
                                              timeLimit: selectedQuestion.timeLimit,
                                              points: selectedQuestion.points,
                                              answers: [updatedTrue, updatedFalse],
                                            );
                                            quizBloc.updateQuestionAt(_selectedIndex, qUpdated);
                                          },
                                          child: Container(
                                            constraints: BoxConstraints(minHeight: constraints.maxHeight * 0.12),
                                            margin: margin,
                                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: (ans.isCorrect) ? Border.all(color: Colors.white, width: 3) : null),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Flexible(
                                                  child: _editingAnswerIds.contains(ans.answerId)
                                                      ? TextFormField(
                                                          initialValue: ans.text ?? '',
                                                          maxLines: 3,
                                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: constraints.maxWidth * 0.04),
                                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                                          onChanged: (txt){
                                                            final q = selectedQuestion;
                                                            final newTrue = q.answers.isNotEmpty ? (q.answers[0].answerId == ans.answerId ? A.Answer(answerId: q.answers[0].answerId, questionId: q.answers[0].questionId, isCorrect: q.answers[0].isCorrect, text: txt, mediaUrl: q.answers[0].mediaUrl) : A.Answer(answerId: q.answers[0].answerId, questionId: q.answers[0].questionId, isCorrect: q.answers[0].isCorrect, text: q.answers[0].text, mediaUrl: q.answers[0].mediaUrl)) : (ans.text == 'Verdadero' ? A.Answer(answerId: ans.answerId, questionId: ans.questionId, isCorrect: ans.isCorrect, text: txt, mediaUrl: ans.mediaUrl) : A.Answer(answerId: 'a_tf_true_$now', questionId: q.questionId, isCorrect: true, text: txt));
                                                            final newFalse = q.answers.length > 1 ? (q.answers[1].answerId == ans.answerId ? A.Answer(answerId: q.answers[1].answerId, questionId: q.answers[1].questionId, isCorrect: q.answers[1].isCorrect, text: txt, mediaUrl: q.answers[1].mediaUrl) : A.Answer(answerId: q.answers[1].answerId, questionId: q.answers[1].questionId, isCorrect: q.answers[1].isCorrect, text: q.answers[1].text, mediaUrl: q.answers[1].mediaUrl)) : (ans.text == 'Falso' ? A.Answer(answerId: ans.answerId, questionId: ans.questionId, isCorrect: ans.isCorrect, text: txt, mediaUrl: ans.mediaUrl) : A.Answer(answerId: 'a_tf_false_$now', questionId: q.questionId, isCorrect: false, text: txt));
                                                            final updated = Q.Question(
                                                              questionId: q.questionId,
                                                              quizId: q.quizId,
                                                              text: q.text,
                                                              mediaUrl: q.mediaUrl,
                                                              type: q.type,
                                                              timeLimit: q.timeLimit,
                                                              points: q.points,
                                                              answers: [newTrue, newFalse],
                                                            );
                                                            quizBloc.updateQuestionAt(_selectedIndex, updated);
                                                          },
                                                        )
                                                      : Center(child: Text(ans.text ?? (ans == trueAns ? 'Verdadero' : 'Falso'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: constraints.maxWidth * 0.045), textAlign: TextAlign.center)),
                                                ),
                                                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                  if (!_editingAnswerIds.contains(ans.answerId))
                                                    IconButton(onPressed: (){ setState(()=> _editingAnswerIds.add(ans.answerId)); _editingInitialValues[ans.answerId] = ans.text ?? ''; }, icon: Icon(Icons.edit, color: Colors.white70, size: constraints.maxWidth * 0.06))
                                                  else
                                                    Row(children: [
                                                      IconButton(onPressed: (){ setState(()=> _editingAnswerIds.remove(ans.answerId)); _editingInitialValues.remove(ans.answerId); }, icon: Icon(Icons.check, color: Colors.white70, size: constraints.maxWidth * 0.06)),
                                                      IconButton(onPressed: (){
                                                        final orig = _editingInitialValues[ans.answerId] ?? '';
                                                        final q = selectedQuestion;
                                                        final newTrue = q.answers.isNotEmpty ? A.Answer(answerId: q.answers[0].answerId, questionId: q.answers[0].questionId, isCorrect: q.answers[0].isCorrect, text: q.answers[0].answerId == ans.answerId ? orig : q.answers[0].text, mediaUrl: q.answers[0].mediaUrl) : (ans.text == 'Verdadero' ? A.Answer(answerId: ans.answerId, questionId: ans.questionId, isCorrect: ans.isCorrect, text: orig, mediaUrl: ans.mediaUrl) : A.Answer(answerId: 'a_tf_true_$now', questionId: q.questionId, isCorrect: true, text: orig));
                                                        final newFalse = q.answers.length > 1 ? A.Answer(answerId: q.answers[1].answerId, questionId: q.answers[1].questionId, isCorrect: q.answers[1].isCorrect, text: q.answers[1].answerId == ans.answerId ? orig : q.answers[1].text, mediaUrl: q.answers[1].mediaUrl) : (ans.text == 'Falso' ? A.Answer(answerId: ans.answerId, questionId: ans.questionId, isCorrect: ans.isCorrect, text: orig, mediaUrl: ans.mediaUrl) : A.Answer(answerId: 'a_tf_false_$now', questionId: q.questionId, isCorrect: false, text: orig));
                                                        final updated = Q.Question(
                                                          questionId: q.questionId,
                                                          quizId: q.quizId,
                                                          text: q.text,
                                                          mediaUrl: q.mediaUrl,
                                                          type: q.type,
                                                          timeLimit: q.timeLimit,
                                                          points: q.points,
                                                          answers: [newTrue, newFalse],
                                                        );
                                                        quizBloc.updateQuestionAt(_selectedIndex, updated);
                                                        setState(()=> _editingAnswerIds.remove(ans.answerId));
                                                        _editingInitialValues.remove(ans.answerId);
                                                      }, icon: Icon(Icons.close, color: Colors.white70, size: constraints.maxWidth * 0.06)),
                                                    ])
                                                ])
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Row(children: [
                                      buildTile(trueAns, Colors.blue, EdgeInsets.only(right: 8)),
                                      buildTile(falseAns, Colors.red, EdgeInsets.only(left: 8)),
                                    ]);
                                  }),

                                // Quiz type: wide colorful tiles with inline editing
                                if (selectedQuestion.type != 'true_false')
                                  Column(
                                    children: [
                                      ...selectedQuestion.answers.asMap().entries.map((entry) {
                                        final idx = entry.key;
                                        final ans = entry.value;
                                        final colors = [Colors.blue, Colors.red, Colors.orange.shade700, Colors.green];
                                        final bg = colors[idx % colors.length];
                                        return GestureDetector(
                                          onTap: (){
                                            final q = selectedQuestion;
                                            final newAnswers = q.answers.map((a) => a.answerId == ans.answerId ? A.Answer(answerId: a.answerId, questionId: a.questionId, isCorrect: !a.isCorrect, text: a.text, mediaUrl: a.mediaUrl) : a).toList();
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
                                          },
                                          child: Container(
                                            width: constraints.maxWidth * 0.94,
                                            margin: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.008),
                                            padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.02, horizontal: constraints.maxWidth * 0.03),
                                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: ans.isCorrect ? Border.all(color: Colors.white, width: 3) : null),
                                            child: Row(
                                              children: [
                                                Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (_editingAnswerIds.contains(ans.answerId))
                                                      TextFormField(
                                                        initialValue: ans.text ?? '',
                                                        maxLines: 3,
                                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: constraints.maxWidth * 0.04),
                                                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                                        onChanged: (txt){
                                                          final q = selectedQuestion;
                                                          final newAnswers = q.answers.map((a) => a.answerId == ans.answerId ? A.Answer(answerId: a.answerId, questionId: a.questionId, isCorrect: a.isCorrect, text: txt, mediaUrl: a.mediaUrl) : a).toList();
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
                                                        },
                                                      )
                                                    else
                                                      Text(ans.text ?? '', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: constraints.maxWidth * 0.04), maxLines: 3, overflow: TextOverflow.ellipsis),
                                                    SizedBox(height: 6),
                                                    Wrap(spacing: 12, runSpacing: 6, children: [
                                                      GestureDetector(onTap: (){
                                                        // start inline edit
                                                        setState((){
                                                          _editingAnswerIds.add(ans.answerId);
                                                          _editingInitialValues[ans.answerId] = ans.text ?? '';
                                                        });
                                                      }, child: Row(children: [Icon(Icons.edit, color: Colors.white70, size: constraints.maxWidth * 0.04), SizedBox(width: 6), Text('Editar', style: TextStyle(color: Colors.white70))])),
                                                      GestureDetector(onTap: (){
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
                                                      }, child: Row(children: [Icon(Icons.delete, color: Colors.white70, size: constraints.maxWidth * 0.04), SizedBox(width: 6), Text('Eliminar', style: TextStyle(color: Colors.white70))])),
                                                      if (_editingAnswerIds.contains(ans.answerId))
                                                        Row(children: [
                                                          IconButton(onPressed: (){ setState(()=> _editingAnswerIds.remove(ans.answerId)); _editingInitialValues.remove(ans.answerId); }, icon: Icon(Icons.check, color: Colors.white70)),
                                                          IconButton(onPressed: (){
                                                            final orig = _editingInitialValues[ans.answerId] ?? '';
                                                            final q = selectedQuestion;
                                                            final newAnswers = q.answers.map((a) => a.answerId == ans.answerId ? A.Answer(answerId: a.answerId, questionId: a.questionId, isCorrect: a.isCorrect, text: orig, mediaUrl: a.mediaUrl) : a).toList();
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
                                                            setState(()=> _editingAnswerIds.remove(ans.answerId));
                                                            _editingInitialValues.remove(ans.answerId);
                                                          }, icon: Icon(Icons.close, color: Colors.white70)),
                                                        ])
                                                    ])
                                                  ],
                                                )),
                                                if (ans.isCorrect)
                                                  Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, color: Colors.white, size: constraints.maxWidth * 0.07))
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),

                                      // Add answer tile
                                      GestureDetector(
                                        onTap: (){
                                          final q = selectedQuestion;
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
                                        },
                                        child: Container(
                                          width: constraints.maxWidth * 0.94,
                                          margin: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.008),
                                          padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.02, horizontal: constraints.maxWidth * 0.03),
                                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                                          child: Center(child: Icon(Icons.add, size: constraints.maxWidth * 0.08)),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            // Acciontes: duplica o elimina un pregunta
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
                                  // Insert locally only
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
                        onPressed: () {
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
                            points: 1000,
                            answers: [a1, a2],
                          );

                          quizBloc.insertQuestionAt(quizBloc.currentQuiz!.questions.length, newQ);
                          setState(()=> _selectedIndex = quizBloc.currentQuiz!.questions.length - 1);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pregunta creada (local). Guarda el quiz para persistirla')));
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

class ThemePreviewDialog extends StatelessWidget {
  final String themeName;
  final Color color;
  const ThemePreviewDialog({Key? key, required this.themeName, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Previsualización', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(themeName, style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 12),
            // Mock phone preview
            Container(
              width: 220,
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: color,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))],
              ),
              child: Stack(
                children: [
                  // Simple center content to resemble preview
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 160,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: 120,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('OK, go!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cerrar')),
                SizedBox(width: 8),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Seleccionar tema')),
              ],
            )
          ],
        ),
      ),
    );
  }
}