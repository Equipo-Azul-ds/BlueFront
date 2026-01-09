import 'package:flutter/material.dart';
import '../../Dominio/entidad/User.dart';


class UserListItem extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  const UserListItem({
    super.key,
    required this.user,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: user.isBlocked ? Colors.red.shade50.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LADO IZQUIERDO: Información del Usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y Estado
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
                    // Indicador de Estado (Activo/Bloqueado)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isBlocked ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.isBlocked ? 'BLOQUEADO' : 'ACTIVO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),

                // Tipo y Fecha de Unión (en una sola línea)
                Text(
                  'Tipo: ${user.userType} | Unido: ${user.createdAt.toLocal().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // LADO DERECHO: Botones de Acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de Bloquear/Desbloquear
              IconButton(
                icon: Icon(
                  user.isBlocked ? Icons.lock_open : Icons.lock,
                  color: user.isBlocked ? Colors.green : Colors.orange,
                ),
                tooltip: user.isBlocked ? 'Desbloquear Usuario' : 'Bloquear Usuario',
                onPressed: onBlock,
              ),

              // Botón de Eliminar
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                tooltip: 'Eliminar Usuario',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}