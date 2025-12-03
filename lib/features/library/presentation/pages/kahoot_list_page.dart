import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../../../common_widgets/subpage_scaffold.dart';
import '../providers/library_provider.dart';
import '../utils/kahoot_list_type.dart';

class KahootListPage extends StatelessWidget {
  final String title;
  final KahootListType listType;

  const KahootListPage({
    super.key,
    required this.title,
    required this.listType,
  });

  void _onKahootTap(BuildContext context, String kahootId) {
    Navigator.pushNamed(context, '/kahoot-detail', arguments: kahootId);
  }

  // Helper para obtener la lista correcta del Provider
  List<Kahoot> _getKahootsFromProvider(LibraryProvider provider) {
    return switch (listType) {
      KahootListType.created => provider.createdKahoots,
      KahootListType.favorites => provider.favoriteKahoots,
      KahootListType.inProgress => provider.inProgressKahoots,
      KahootListType.completed => provider.completedKahoots,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        final kahoots = _getKahootsFromProvider(provider);

        // Manejo de estado
        if (provider.state == LibraryState.loading && kahoots.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SubpageScaffold(
          title: title,
          baseIndex: 3,
          body: kahoots.isEmpty
              ? Center(child: Text('No hay Kahoots en $title.'))
              : ListView.builder(
                  itemCount: kahoots.length,
                  itemBuilder: (context, index) {
                    final kahoot = kahoots[index];
                    final String kahootId = kahoot.id;

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
      },
    );
  }
}
