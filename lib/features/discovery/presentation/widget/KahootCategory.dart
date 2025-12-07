import 'package:flutter/material.dart';
import '../../../kahoot/domain/entities/kahoot.dart';
import 'kahootListItem.dart';

final kDummyKahoots = [
  Kahoot(
    id: 'd-001',
    title: 'Dummy: Matemáticas Básicas',
    description: 'Quices de prueba para operaciones fundamentales.',
    kahootImage: 'assets/images/placeholder.png',
    visibility: 'public',
    status: 'published',
    themes: ['Matemáticas'],
    author: 'auth-dummy',
    createdAt: DateTime(2025, 11, 25),
    playCount: 1500,
  ),
  Kahoot(
    id: 'd-002',
    title: 'Dummy: Historia del Arte',
    description: 'Viaje por el Renacimiento.',
    kahootImage: 'assets/images/placeholder.png',
    visibility: 'public',
    status: 'published',
    themes: ['Arte', 'Historia'],
    author: 'auth-dummy',
    createdAt: DateTime(2025, 11, 20),
    playCount: 800,
  ),
  Kahoot(
    id: 'd-003',
    title: 'Dummy: Ciencia Ficción',
    description: 'Preguntas sobre los clásicos del género.',
    kahootImage: 'assets/images/placeholder.png',
    visibility: 'public',
    status: 'published',
    themes: ['Cine', 'Literatura'],
    author: 'auth-dummy',
    createdAt: DateTime(2025, 10, 15),
    playCount: 2200,
  ),
];

class KahootCategorySection extends StatefulWidget {
  final String categoryTitle;

  const KahootCategorySection({
    super.key,
    required this.categoryTitle,
  });

  @override
  State<KahootCategorySection> createState() => _KahootCategorySectionState();
}

class _KahootCategorySectionState extends State<KahootCategorySection> {
  /*List<Kahoot> _kahoots = [];
  bool _isLoading = true;
  String? _error;*/
  List<Kahoot> _kahoots = kDummyKahoots;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    //Future.microtask(_fetchCategoryKahoots);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_kahoots.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text('No hay Kahoots en la categoría "${widget.categoryTitle}".'),
        ),
      );
    } else {
      content = SizedBox(
        height: 200,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: buildKahootWidgets(context, _kahoots),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16,
              16, 16, 8),
          child: Text(
            widget.categoryTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),


        content,

        const SizedBox(height: 10),
      ],
    );
  }
}

List<Widget> buildKahootWidgets(BuildContext context, List<Kahoot> kahoots) {
  return kahoots.asMap().entries.map((entry) {
    int index = entry.key;
    Kahoot kahoot = entry.value;

    return SizedBox(
      width: 250,
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: KahootListItem(
          number: (index + 1).toString(),
          title: kahoot.title,
          source: kahoot.author,
          image: kahoot.kahootImage,
          onTap: () {
            Navigator.of(context).pushNamed(
              '/kahoot-detail', //pagina de detalles del kahoot nombre temporal
              arguments: kahoot.id,
            );
          },
        ),
      ),
    );
  }).toList();
}