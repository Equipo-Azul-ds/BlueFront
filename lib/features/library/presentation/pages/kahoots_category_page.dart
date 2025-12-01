import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../../../common_widgets/subpage_scaffold.dart';
import 'kahoot_list_page.dart';

class KahootsCategoryPage extends StatelessWidget {
  const KahootsCategoryPage({super.key});

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

          final draftKahoots = provider.createdKahoots
              .where((k) => k.status == 'Borrador')
              .toList();
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
                'Borradores',
                draftKahoots,
                Icons.edit,
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
                builder: (context) =>
                    KahootListPage(title: title, kahoots: kahoots),
              ),
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
