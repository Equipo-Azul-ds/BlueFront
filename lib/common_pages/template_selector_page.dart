//Esta es la pagina para seleccionar plantilla (parte de epica 2 - Crear Kahoot)
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../features/kahoot/domain/entities/Quiz.dart';
import '../common_widgets/staggered_grid.dart';
import '../common_widgets/kahoot_card.dart';

class TemplateSelectorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    //Simulo plantillas
    final templates = [
      Quiz(quizId: 't1', authorId: 'System', title: 'Template 1', description: '', visibility: 'public', themeId: '', createdAt: DateTime.now(), questions: []),
      Quiz(quizId: 't2', authorId: 'System', title: 'Template 2', description: '', visibility: 'public', themeId: '', createdAt: DateTime.now(), questions: []),
      Quiz(quizId: 't3', authorId: 'System', title: 'Template 3', description: '', visibility: 'public', themeId: '', createdAt: DateTime.now(), questions: []),
      Quiz(quizId: 't4', authorId: 'System', title: 'Template 4', description: '', visibility: 'public', themeId: '', createdAt: DateTime.now(), questions: []),
      Quiz(quizId: 't5', authorId: 'System', title: 'Template 5', description: '', visibility: 'public', themeId: '', createdAt: DateTime.now(), questions: []),
      Quiz(quizId: 't6', authorId: 'System', title: 'Template 6', description: '', visibility: 'public', themeId: '', createdAt: DateTime.now(), questions: []),
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
