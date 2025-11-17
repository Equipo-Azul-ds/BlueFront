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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth * 0.04),
            child: Column(
              children: [
                TextField(
                  controller: TextEditingController(text: slide.text),
                  decoration: InputDecoration(
                    labelText: 'Texto del Slide',
                    contentPadding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: constraints.maxHeight * 0.015),
                  ),
                  style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                //Mas adelante agrega opcciones, tiempo, puntos....
                ElevatedButton(
                  onPressed:()=>bloc.updateSlide('kahootId', slideId, {}),
                  child: Text(
                    'Guardar',
                    style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, constraints.maxHeight * 0.06),
                    padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.015),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
