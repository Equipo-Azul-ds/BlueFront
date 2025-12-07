import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final String userId = 'user_123';

  @override
  void initState() {
    super.initState();
    // La carga se inicia cuando la página se inserta en el IndexedStack por primera vez.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).loadAllLists(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            AppBar(
              title: const Text('Biblioteca'),
              automaticallyImplyLeading: false,
            ),
            Expanded(child: _buildBody(provider)),
          ],
        );
      },
    );
  }

  Widget _buildBody(LibraryProvider provider) {
    if (provider.state == LibraryState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == LibraryState.error) {
      return const Center(child: Text('Error al cargar la biblioteca.'));
    }

    // La vista principal de la Biblioteca con las categorías de alto nivel
    return ListView(
      children: [
        // Botón principal "Tus Kahoots"
        _buildCategoryTile(
          icon: Icons.person_outline,
          title: 'Tus Kahoots',
          onTap: () {
            Navigator.of(context).pushNamed('/kahoots-category').then((_) {
              if (!mounted) return;
              Provider.of<LibraryProvider>(
                context,
                listen: false,
              ).loadAllLists(userId);
            });
          },
        ),

        const Divider(height: 1, indent: 16, endIndent: 16),

        // Otras categorías
        _buildCategoryTile(
          icon: Icons.group,
          title: 'Grupos de Estudio',
          onTap: () {},
        ),
        _buildCategoryTile(
          icon: Icons.school_outlined,
          title: 'Cursos',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
