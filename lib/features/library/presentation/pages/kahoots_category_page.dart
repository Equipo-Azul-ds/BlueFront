import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../../domain/entities/kahoot_model.dart';
import 'kahoot_list_page.dart';
import '../utils/kahoot_list_type.dart';

class KahootsCategoryPage extends StatelessWidget {
  const KahootsCategoryPage({super.key});

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
    // CAMBIO: Usamos Scaffold normal de Flutter
    return Scaffold(
      appBar: AppBar(title: const Text('Tus Kahoots'), elevation: 0),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildCategoryTile(
                context,
                'Creados',
                publishedKahoots,
                Icons.inventory_2_outlined,
              ),
              _buildCategoryTile(
                context,
                'Favoritos',
                provider.favoriteKahoots,
                Icons.favorite_border,
              ),
              _buildCategoryTile(
                context,
                'En Progreso',
                provider.inProgressKahoots,
                Icons.play_circle_outline,
              ),
              _buildCategoryTile(
                context,
                'Completados',
                provider.completedKahoots,
                Icons.check_circle_outline,
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
          leading: Icon(icon, color: Colors.blueGrey[700]),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {
            // Mantenemos el rootNavigator: true para "tapar" la barra de abajo
            Navigator.of(context, rootNavigator: true).push(
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
