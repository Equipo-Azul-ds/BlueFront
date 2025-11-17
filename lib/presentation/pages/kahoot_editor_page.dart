import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../blocs/kahoot_editor_bloc.dart';
import '../blocs/slide_editor_bloc.dart';
import '../widgets/media_upload.dart' as media;

class KahootEditorPage extends StatefulWidget{
  @override
  _KahootEditionPageState createState() => _KahootEditionPageState();
}

class _KahootEditionPageState extends State<KahootEditorPage>{
  int _step = 1; //Paso 1: detalles, paso 2: slides
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context){
    final kahootBloc = Provider.of<KahootEditorBloc>(context);
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
                    //Subir imagen
                    media.MediaUpload(onMediaSelected: (file) => kahootBloc.updateKahoot({'kahootImage': file.path})),
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
                      value: true, //esto lo simulo
                      onChanged: (val) => kahootBloc.updateKahoot({'visibility': val ? 'public' : 'private'}),
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
          IconButton(onPressed: ()=> kahootBloc.unpublishKahoot(), icon: Icon(Icons.save)),
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