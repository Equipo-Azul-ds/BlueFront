import 'package:flutter/material.dart';
import '../../Dominio/entidad/User.dart';


class UserListItem extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onBlock;
  final VoidCallback onDelete;
  final VoidCallback onToggleAdmin; // Nuevo callback

  const UserListItem({
    super.key,
    required this.user,
    required this.onBlock,
    required this.onDelete,
    required this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: user.isBlocked ? Colors.red.shade50.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: user.isBlocked ? Colors.red.shade800 : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Etiqueta visual si es Admin
                    if (user.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("ADMIN", style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  'Username: @${user.username} | Unido: ${user.formattedJoinDate}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // BOTONES DE ACCIÓN
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Admin (Nuevo)
              IconButton(
                icon: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person_add_alt_1,
                  color: user.isAdmin ? Colors.amber : Colors.grey,
                ),
                tooltip: user.isAdmin ? 'Quitar privilegios Admin' : 'Hacer Administrador',
                onPressed: onToggleAdmin,
              ),

              // Botón Bloquear
              IconButton(
                icon: Icon(
                  user.isBlocked ? Icons.lock_open : Icons.lock,
                  color: user.isBlocked ? Colors.green : Colors.orange,
                ),
                onPressed: onBlock,
              ),

              // Botón Eliminar
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}