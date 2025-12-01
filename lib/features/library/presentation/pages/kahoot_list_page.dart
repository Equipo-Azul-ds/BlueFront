import 'package:flutter/material.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../../../common_widgets/subpage_scaffold.dart';

class KahootListPage extends StatelessWidget {
  final String title;
  final List<Kahoot> kahoots;

  const KahootListPage({super.key, required this.title, required this.kahoots});

  void _onKahootTap(BuildContext context, String kahootId) {
    Navigator.pushNamed(
      context,
      '/kahoot-detail',
      arguments:
          kahootId, // Pasamos el ID para que la página de detalle sepa qué cargar
    );
  }

  @override
  Widget build(BuildContext context) {
    return SubpageScaffold(
      title: title,
      baseIndex: 3,
      body: kahoots.isEmpty
          ? Center(child: Text('No hay Kahoots en $title.'))
          : ListView.builder(
              itemCount: kahoots.length,
              itemBuilder: (context, index) {
                final kahoot = kahoots[index];

                final String kahootId = (kahoot as dynamic).id;

                return ListTile(
                  title: Text(kahoot.title),
                  subtitle: Text('Autor: ${kahoot.authorId}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _onKahootTap(context, kahootId);
                  },
                );
              },
            ),
    );
  }
}
