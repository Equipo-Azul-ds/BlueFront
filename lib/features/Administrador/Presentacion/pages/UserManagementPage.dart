import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Dominio/entidad/User.dart';
import '../Widget/UserListItem.dart';
import '../provider/UserManagementProvider.dart';


class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final String adminId = 'admin_456';

  @override
  void initState() {
    super.initState();
    // Llama al Provider para iniciar la carga de usuarios justo después de que el widget se inserte.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usamos context.read ya que solo queremos llamar al método, no reconstruir.
      context.read<UserManagementProvider>().loadUsers(adminId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      // Usamos Consumer para escuchar los cambios en el estado del Provider
      body: Consumer<UserManagementProvider>(
        builder: (context, provider, child) {

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error al cargar usuarios. Intente de nuevo.'),
                  TextButton(
                    // Llama al método del Provider para reintentar
                    onPressed: () => provider.loadUsers(adminId),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final users = provider.users;
          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return UserListItem(
                user: user,
                // Los callbacks llaman al provider a través de los diálogos de confirmación
                onBlock: () => _confirmBlockUser(context, user),
                onDelete: () => _confirmDeleteUser(context, user),
              );
            },
          );
        },
      ),
    );
  }

  // Lógica de diálogos de confirmación
  void _confirmBlockUser(BuildContext context, UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isBlocked ? 'Desbloquear Usuario' : 'Bloquear Usuario'),
        // ... (Contenido del diálogo)
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Llamada al Provider (se actualiza la lista automáticamente)
              context.read<UserManagementProvider>().toggleBlockStatus(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(user.isBlocked ? 'Desbloquear' : 'Bloquear'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        // ... (Contenido del diálogo)
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Llamada al Provider (se actualiza la lista automáticamente)
              context.read<UserManagementProvider>().deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}