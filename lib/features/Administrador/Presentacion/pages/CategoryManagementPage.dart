import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../discovery/domain/entities/theme.dart';
import '../provider/CategotyManagementProvider.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryManagementProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryManagementProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Categorías')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: provider.categories.length,
        itemBuilder: (context, index) {
          final cat = provider.categories[index];
          return ListTile(
            title: Text(cat.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showFormDialog(context, cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => provider.deleteCategory(cat.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFormDialog(BuildContext context, ThemeVO? category) {
    final controller = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == null ? 'Nueva Categoría' : 'Editar Categoría'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Nombre del tema')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (category == null) {
                context.read<CategoryManagementProvider>().createCategory(controller.text);
              } else {
                context.read<CategoryManagementProvider>().updateCategory(category.id, controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}