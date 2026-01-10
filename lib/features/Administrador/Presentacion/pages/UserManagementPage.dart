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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().loadUsers(adminId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
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
                onBlock: () => _confirmBlockUser(context, user),
                onDelete: () => _confirmDeleteUser(context, user),
                onToggleAdmin: () => _confirmToggleAdmin(context, user),
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
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
  void _confirmToggleAdmin(BuildContext context, UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isAdmin ? 'Quitar privilegios' : 'Dar privilegios'),
        content: Text('¿Deseas cambiar el estatus de administrador para ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserManagementProvider>().toggleAdminRole(user.id);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}