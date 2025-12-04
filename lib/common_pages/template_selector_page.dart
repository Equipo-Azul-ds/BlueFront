//Esta es la pagina para seleccionar plantilla (parte de epica 2 - Crear Kahoot)
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../features/kahoot/domain/entities/kahoot.dart';
import '../common_widgets/staggered_grid.dart';
import '../common_widgets/kahoot_card.dart';

class TemplateSelectorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    //Simulo plantillas
    final templates = [
      Kahoot(id: 't1', title: 'Template 1', visibility: 'publico', status: 'publico', themes: [], author: 'System', createdAt: DateTime.now()),
      Kahoot(id: 't2', title: 'Template 2', visibility: 'publico', status: 'publico', themes: [], author: 'System', createdAt: DateTime.now()),
      Kahoot(id: 't3', title: 'Template 3', visibility: 'publico', status: 'publico', themes: [], author: 'System', createdAt: DateTime.now()),
      Kahoot(id: 't4', title: 'Template 4', visibility: 'publico', status: 'publico', themes: [], author: 'System', createdAt: DateTime.now()),
      Kahoot(id: 't5', title: 'Template 5', visibility: 'publico', status: 'publico', themes: [], author: 'System', createdAt: DateTime.now()),
      Kahoot(id: 't6', title: 'Template 6', visibility: 'publico', status: 'publico', themes: [], author: 'System', createdAt: DateTime.now()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Selecciona la plantilla que mas te guste!')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(constraints.maxWidth * 0.04),
            child: StaggeredGrid(
              children: templates.map((t)=>KahootCard(kahoot: t, onTap:()=>Navigator.pop(context,t))).toList(),
            ),
          );
        },
      ),
    );
  }
}
