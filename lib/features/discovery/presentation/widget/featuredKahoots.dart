import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../kahoot/domain/entities/kahoot.dart';
import '../../domain/Repositories/IDiscoverRepository.dart';
import '../../infraestructure/repositories/DiscoverRepository.dart';
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


class FeaturedKahoots extends StatefulWidget {
  const FeaturedKahoots({
    super.key,
  });

  @override
  State<FeaturedKahoots> createState() => _FeaturedKahootsState();
}

class _FeaturedKahootsState extends State<FeaturedKahoots> {
  /*List<Kahoot> _kahoots = [];
  bool _isLoading = true;
  String? _error;*/
  List<Kahoot> _kahoots = kDummyKahoots;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    //Future.microtask(_fetchFeaturedKahoots);
  }

  Future<void> _fetchFeaturedKahoots() async {
    try {
      final repository = context.read<IDiscoverRepository>();
      const limit = 10;

      final result = await repository.getFeaturedKahoots(limit: limit);

      result.fold(
            (failure) {
          if (mounted) {
            setState(() {
              _error = 'Error al cargar Kahoots destacados: ${failure.runtimeType}';
              _isLoading = false;
            });
          }
        },
            (kahoots) {
          if (mounted) {
            setState(() {
              _kahoots = kahoots;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocurrió un error inesperado: $e';
          _isLoading = false;
        });
      }
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
      content = const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text('No hay Kahoots destacados disponibles.'),
        ),
      );
    } else {
      // Mostrar la lista horizontal con los datos obtenidos
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
            "Featured Kahoots",
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
              '/kahoot-detail',  //pagina de detalles del kahoot nombre temporal
              arguments: kahoot.id,
            );
          },
        ),
      ),
    );
  }).toList();
}