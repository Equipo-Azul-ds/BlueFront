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

class KahootSearch extends StatefulWidget {
  final String searchTitle;

  const KahootSearch({
    super.key,
    required this.searchTitle,
  });

  @override
  State<KahootSearch> createState() => _KahootSearchState();
}

class _KahootSearchState extends State<KahootSearch> {
  List<Kahoot> _kahoots = kDummyKahoots;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchKahoots(widget.searchTitle);
  }


  @override
  void didUpdateWidget(covariant KahootSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchTitle != widget.searchTitle) {
      _fetchKahoots(widget.searchTitle);
    }
  }

  Future<void> _fetchKahoots(String query) async {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = null;
        // Filtra dummies por título si hay query
        _kahoots = query.isEmpty
            ? kDummyKahoots
            : kDummyKahoots
                .where((k) =>
                    k.title.toLowerCase().contains(query.toLowerCase()))
                .toList();
      });
    }
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
          child: Text('No se encontraron Kahoots para "${widget.searchTitle}".'),
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
            'Resultados de la búsqueda: "${widget.searchTitle}"',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        content,
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