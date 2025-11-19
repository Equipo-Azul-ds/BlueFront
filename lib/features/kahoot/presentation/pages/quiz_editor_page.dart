import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../blocs/quiz_editor_bloc.dart';
import '../../../media/presentation/blocs/media_editor_bloc.dart';
import '../../../../common_widgets/media_upload.dart' as media;
import '../../application/dtos/create_quiz_dto.dart';

class QuizEditorPage extends StatefulWidget{
  @override
  _QuizEditorPageState createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage>{
  int _step = 1; //Paso 1: detalles, paso 2: slides
  final _formKey = GlobalKey<FormBuilderState>();

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
    final slideBloc = Provider.of<SlideEditorBloc>(context);

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
                      decoration: InputDecoration(
                        labelText:'Titulo',
                        contentPadding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: constraints.maxHeight * 0.015),
                      ),
                      style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    FormBuilderTextField(
                      name: 'description',
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
                    //Formulario de slide actual
                    Container(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                      decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText:'Escribe tu pregunta aqui....',
                              contentPadding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: constraints.maxHeight * 0.015),
                            ),
                            style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.0125),
                          media.MediaUpload(onMediaSelected: (file)=>slideBloc.updateSlide('kahootId', 'slideId',{'mediaUrl': file.path})),
                          //opciones de respuesta (simplificado para que quede como prueba)
                          Row(children: [Text('Opciones aqui...', style: TextStyle(fontSize: constraints.maxWidth * 0.035))]),
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
                  itemCount: slideBloc.slides.length + 1,
                  itemBuilder: (contact, index){
                    if(index == slideBloc.slides.length){
                      return IconButton(
                        onPressed:()=>slideBloc.createSlide('kahootId', {}),
                        icon: Icon(Icons.add),
                        iconSize: constraints.maxWidth * 0.06);
                    }
                    return Container(
                      width: constraints.maxWidth * 0.1,
                      margin: EdgeInsets.all(constraints.maxWidth * 0.02),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('Q${index + 1}', style: TextStyle(fontSize: constraints.maxWidth * 0.035))),
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