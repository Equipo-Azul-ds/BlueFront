import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../kahoot/domain/entities/kahoot.dart';
import '../../domain/Repositories/IDiscoverRepository.dart';
import '../../infraestructure/repositories/DiscoverRepository.dart';
import 'kahootListItem.dart';



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

    final repository = context.read<IDiscoverRepository>();

    try {

      final result = await repository.getKahoots(
        query: null,
        themes: [widget.categoryTitle],
        orderBy: 'createdAt',
        order: 'desc',
      );

      result.fold(
            (failure) {
          if (mounted) {
            setState(() {
              _error = 'Error al cargar kahoots de ${widget.categoryTitle}: ${failure.runtimeType}';
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