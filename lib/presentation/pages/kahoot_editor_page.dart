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
        appBar: AppBar(title: Text('Crear nuevo Kahoot'), backgroundColor: AppColor.primary),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children:[
                //Subir imagen
                media.MediaUpload(onMediaSelected: (file) => kahootBloc.updateKahoot({'kahootImage': file.path})),
                FormBuilderTextField(name: 'title', decoration: InputDecoration(labelText:'Titulo')),
                FormBuilderTextField(name: 'description', decoration: InputDecoration(labelText:'Descripcion')),
                SwitchListTile(
                  title: Text('Visible para todos'),
                  value: true, //esto lo simulo
                  onChanged: (val) => kahootBloc.updateKahoot({'visibility': val ? 'public' : 'private'}),
                ),
                ElevatedButton(
                  onPressed: () => setState(()=>_step = 2),
                  child: Text('Continuar a preguntas'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    //Paso 2: Ediotr de Slides
    return Scaffold(
      appBar: AppBar(
        title: Text('Editando'),
        actions: [
          IconButton(onPressed: ()=> kahootBloc.unpublishKahoot(), icon: Icon(Icons.save)),
        ]
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                //Formulario de slide actual
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      TextField(decoration: InputDecoration(hintText:'Escribe tu pregunta aqui....')),
                      SizedBox(height:10),
                      media.MediaUpload(onMediaSelected: (file)=>slideBloc.updateSlide('kahootId', 'slideId',{'mediaUrl': file.path})),
                      //opciones de respuesta (simplificado para que quede como prueba)
                      Row(children: [Text('Opciones aqui...')]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          //Barra inferior de los slides
          Container(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: slideBloc.slides.length + 1,
              itemBuilder: (contact, index){
                if(index == slideBloc.slides.length){
                  return IconButton(onPressed:()=>slideBloc.createSlide('kahootId', {}), icon: Icon(Icons.add));
                }
                return Container(
                  width: 40,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('Q${index} + 1')),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}