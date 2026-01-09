import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/kahoot.dart';
import '../../domain/Repositories/IDiscoverRepository.dart';
import '../Funciones/buildKahootWidgets.dart';



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
  List<Kahoot> _kahoots = [];
  bool _isLoading = true;
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
    print('[dashboard] _fetchKahoots START -> query="$query"');

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
        _kahoots = [];
      });
    }

    if (query.isEmpty) {
      print('[dashboard] _fetchKahoots SKIPPED -> query is empty');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Se cambia context.read<IDiscoverRepository>() por Provider.of<...>(context, listen: false)
      // para ser consistente con el primer fragmento de código.
      final repository = Provider.of<IDiscoverRepository>(context, listen: false);

      final result = await repository.getKahoots(
        query: query,
        themes: const [],
        orderBy: 'createdAt',
        order: 'desc',
      );

      result.fold(
            (failure) {
          print(
            '[dashboard] fetchKahoots FAILED for query="$query" -> Failure: ${failure.runtimeType}',
          );
          if (mounted) {
            setState(() {
              _error = 'Error al buscar Kahoots: ${failure.runtimeType}';
              _isLoading = false;
            });
          }
        },
            (kahoots) {
          print(
            '[dashboard] fetchKahoots SUCCESS for query="$query" -> count: ${kahoots.length}',
          );
          if (mounted) {
            setState(() {
              _kahoots = kahoots;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e, st) { // Se añade 'st' para el StackTrace
      print(
        '[dashboard] Exception fetching Kahoots for query="$query" -> $e',
      );
      print(st); // Imprimir el StackTrace como en el código anterior
      if (mounted) {
        setState(() {
          _error = 'Ocurrió un error inesperado durante la búsqueda: $e';
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


