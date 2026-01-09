import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/kahoot.dart';
import '../../domain/Repositories/IDiscoverRepository.dart';
import '../Funciones/buildKahootWidgets.dart';



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
  List<Kahoot> _kahoots = [];
  bool _isLoading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchCategoryKahoots);
  }

  Future<void> _fetchCategoryKahoots() async {
    print('[dashboard] _fetchCategoryKahoots -> category=${widget.categoryTitle}');

    final repository = Provider.of<IDiscoverRepository>(context, listen: false);

    try {
      final result = await repository.getKahoots(
        query: null,
        themes: [widget.categoryTitle],
        orderBy: 'createdAt',
        order: 'desc',
      );

      result.fold(
            (failure) {
          print(
            '[dashboard] fetchCategoryKahoots FAILED for ${widget.categoryTitle} -> Failure: ${failure.runtimeType}',
          );
          if (mounted) {
            setState(() {
              _error =
              'Error al cargar kahoots de ${widget.categoryTitle}: ${failure.runtimeType}';
              _isLoading = false;
            });
          }
        },
            (kahoots) {
          print(
            '[dashboard] fetchCategoryKahoots SUCCESS for ${widget.categoryTitle} -> count: ${kahoots.length}',
          );
          if (mounted) {
            setState(() {
              _kahoots = kahoots;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e, st) {
      print(
        '[dashboard] Exception fetching Kahoots for ${widget.categoryTitle} -> $e',
      );
      print(st);
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

