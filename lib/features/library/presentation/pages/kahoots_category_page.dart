import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../../../common_widgets/subpage_scaffold.dart';
import 'kahoot_list_page.dart';
import '../utils/kahoot_list_type.dart';

class KahootsCategoryPage extends StatelessWidget {
  const KahootsCategoryPage({super.key});

  // Helper para mapear el título del ListTile al tipo de lista requerido
  KahootListType _mapTitleToListType(String title) {
    return switch (title) {
      'Creados' => KahootListType.created,
      'Favoritos' => KahootListType.favorites,
      'En Progreso' => KahootListType.inProgress,
      'Completados' => KahootListType.completed,
      _ => KahootListType.created,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SubpageScaffold(
      title: 'Tus Kahoots',
      baseIndex: 3,
      body: Consumer<LibraryProvider>(
        builder: (context, provider, child) {
          if (provider.state == LibraryState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.state == LibraryState.error) {
            return const Center(child: Text('Error al cargar Kahoots.'));
          }

          final publishedKahoots = provider.createdKahoots
              .where((k) => k.status != 'Borrador')
              .toList();

          return ListView(
            children: [
              _buildCategoryTile(
                context,
                'Creados',
                publishedKahoots,
                Icons.inventory_2,
              ),

              _buildCategoryTile(
                context,
                'Favoritos',
                provider.favoriteKahoots,
                Icons.favorite,
              ),

              _buildCategoryTile(
                context,
                'En Progreso',
                provider.inProgressKahoots,
                Icons.trending_up,
              ),

              _buildCategoryTile(
                context,
                'Completados',
                provider.completedKahoots,
                Icons.check_circle,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    String title,
    List<Kahoot> kahoots,
    IconData icon,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blueGrey),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => KahootListPage(
                  title: title,
                  listType: _mapTitleToListType(title),
                ),
              ),
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
