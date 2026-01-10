import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/kahoot_model.dart';
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
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/kahoot-detail', arguments: kahootId);
  }

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
    return Scaffold(
      appBar: AppBar(title: Text(title), elevation: 0),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, child) {
          final kahoots = _getKahootsFromProvider(provider);

          if (provider.state == LibraryState.loading && kahoots.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (kahoots.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kahoots.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final kahoot = kahoots[index];
              return _buildKahootCard(context, kahoot);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay nada en $title',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKahootCard(BuildContext context, Kahoot kahoot) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.quiz_outlined, color: Colors.blue),
        ),
        title: Text(
          kahoot.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              kahoot.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Autor: ${kahoot.authorName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _onKahootTap(context, kahoot.id),
      ),
    );
  }
}
