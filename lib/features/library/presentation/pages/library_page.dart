import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../../../user/presentation/blocs/auth_bloc.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthBloc>(context, listen: false);
      final uid = auth.currentUser?.id;

      if (mounted) {
        setState(() {
          _userId = uid;
        });
      }

      if (uid != null) {
        Provider.of<LibraryProvider>(context, listen: false).loadAllLists(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Biblioteca'),
            automaticallyImplyLeading: false,
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(LibraryProvider provider) {
    if (provider.state == LibraryState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == LibraryState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error al cargar la biblioteca.'),
            TextButton(
              onPressed: () =>
                  _userId != null ? provider.loadAllLists(_userId!) : null,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        _buildCategoryTile(
          icon: Icons.person_outline,
          title: 'Tus Kahoots',
          onTap: () {
            Navigator.of(context).pushNamed('/kahoots-category').then((_) {
              if (!mounted || _userId == null) return;
              provider.loadAllLists(_userId!);
            });
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _buildCategoryTile(
          icon: Icons.group,
          title: 'Grupos de Estudio',
          onTap: () => Navigator.of(context).pushNamed('/groups'),
        ),
        _buildCategoryTile(
          icon: Icons.school_outlined,
          title: 'Cursos',
          onTap: () {
            // Placeholder para futura funcionalidad
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Próximamente...')));
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
