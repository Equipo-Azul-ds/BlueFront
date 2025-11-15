//Pagina para editar u slide especifico
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../blocs/slide_editor_bloc.dart';

class SlideEditorPage extends StatelessWidget{
  final String slideId;

  SlideEditorPage({required this.slideId});

  @override
  Widget build(BuildContext context){
    final bloc = Provider.of<SlideEditorBloc>(context);
    final slide = bloc.slides.firstWhere((s) => s.id == slideId);

    return Scaffold(
      appBar: AppBar(title: Text('Editor Slide')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: TextEditingController(text: slide.text), decoration: InputDecoration(labelText: 'Texto del Slide')),
            //Mas adelante agrega opcciones, tiempo, puntos....
            ElevatedButton(onPressed:()=>bloc.updateSlide('kahootId', slideId, {}),child:Text('Guardar')),
          ],
        ),
      ),
    );
  }
}