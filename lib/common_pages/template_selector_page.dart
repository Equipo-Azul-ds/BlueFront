import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../features/kahoot/domain/entities/Quiz.dart';

/// Página que muestra plantillas visuales para que el usuario elija
/// Al seleccionar "Usar plantilla" devuelve por `Navigator.pop(context, Quiz)`
class TemplateSelectorPage extends StatelessWidget {
  TemplateSelectorPage({Key? key}) : super(key: key);

  final List<Map<String, String>> _templates = [
    {
      'id': 'tpl_001',
      'title': 'Estudia con preguntas de verdadero o falso',
      'description': 'Plantilla con preguntas tipo verdadero/falso, ideal para repaso rápido.',
      'image': 'https://via.placeholder.com/400x200.png?text=V+o+F',
      'themeId': 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4'
    },
    {
      'id': 'tpl_002',
      'title': 'Presentación interactiva',
      'description': 'Formato con imágenes destacadas por pregunta y varias opciones.',
      'image': 'https://via.placeholder.com/400x200.png?text=Presentacion',
      'themeId': 'd2ad3a12-4f1b-4c3e-9f2a-1a2b3c4d5e6f'
    },
    {
      'id': 'tpl_003',
      'title': 'Trivia visual',
      'description': 'Plantilla enfocada en preguntas con imágenes y tiempo reducido.',
      'image': 'https://via.placeholder.com/400x200.png?text=Trivia',
      'themeId': 'a3b9c8d7-1234-4ef0-9abc-0d1e2f3a4b5c'
    },
  ];

  void _showPreview(BuildContext context, Map<String, String> tpl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tpl['title'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              tpl['image'] ?? '',
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                height: 140,
                color: Colors.grey[300],
                child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey[700])),
              ),
            ),
            SizedBox(height: 8),
            Text(tpl['description'] ?? ''),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
          ElevatedButton(onPressed: () {
            Navigator.of(context).pop();
            // Build a Quiz instance populated with template metadata and return it
            final quiz = Quiz(
              quizId: '',
              authorId: 'author-id-placeholder',
              title: tpl['title'] ?? '',
              description: tpl['description'] ?? '',
              visibility: 'private',
              status: 'draft',
              category: 'General',
              themeId: tpl['themeId'] ?? '',
              templateId: tpl['id'],
              coverImageUrl: tpl['image'],
              createdAt: DateTime.now(),
              questions: [],
            );
            Navigator.of(context).pop(quiz);
          }, child: Text('Usar plantilla')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Selecciona una plantilla')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, childAspectRatio: 1.7, mainAxisSpacing: 12),
          itemCount: _templates.length,
          itemBuilder: (context, index) {
            final tpl = _templates[index];
            return Card(
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Expanded(
                    child: Image.network(
                      tpl['image'] ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[300],
                        child: Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey[700])),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tpl['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(tpl['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                        ])),
                        Column(children: [
                          TextButton(onPressed: () => _showPreview(context, tpl), child: Text('Vista previa')),
                          ElevatedButton(onPressed: () {
                            final quiz = Quiz(
                              quizId: '',
                              authorId: 'author-id-placeholder',
                              title: tpl['title'] ?? '',
                              description: tpl['description'] ?? '',
                              visibility: 'private',
                              status: 'draft',
                              category: 'General',
                              themeId: tpl['themeId'] ?? '',
                              templateId: tpl['id'],
                              coverImageUrl: tpl['image'],
                              createdAt: DateTime.now(),
                              questions: [],
                            );
                            Navigator.of(context).pop(quiz);
                          }, child: Text('Usar plantilla')),
                        ])
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
