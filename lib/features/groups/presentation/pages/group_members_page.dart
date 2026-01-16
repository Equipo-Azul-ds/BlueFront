import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/Group.dart';
import '../../domain/entities/GroupMember.dart';
import '../../domain/entities/GroupRole.dart';
import '../blocs/groups_bloc.dart';
import '../../../user/presentation/blocs/auth_bloc.dart';

class GroupMembersPage extends StatefulWidget {
  final Group group;
  const GroupMembersPage({super.key, required this.group});

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  bool _loading = true;
  String? _error;
  late List<GroupMember> _members;

  @override
  void initState() {
    super.initState();
    _members = widget.group.members;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final bloc = context.read<GroupsBloc>();
      final refreshed = await bloc.getMembers(widget.group.id);
      if (mounted) {
        setState(() {
          _members = refreshed ?? _members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los miembros';
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text('¿Estás seguro de que quieres eliminar a $memberName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _loading = true);
      try {
        final bloc = context.read<GroupsBloc>();
        await bloc.removeMember(widget.group.id, memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Miembro eliminado')),
          );
          _load(); // Recargar lista
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al eliminar: $e')),
           );
            setState(() => _loading = false);
         }
      }
    }
  }

  Future<void> _transferAdmin(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transferir rol de Administrador'),
        content: Text('¿Estás seguro de que quieres nombrar a $memberName como nuevo Administrador?\n\nPerderás tus privilegios administrativos sobre este grupo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Transferir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _loading = true);
      try {
        final bloc = context.read<GroupsBloc>();
        await bloc.transferAdmin(widget.group.id, memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol de administrador transferido')),
          );
          // Al perder admin, quizás lo mejor sea volver atrás o recargar.
          // Recargamos para ver el cambio de roles.
          _load();
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al transferir rol: $e')),
           );
            setState(() => _loading = false);
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Miembros', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_members.isEmpty) {
      return const Center(child: Text('Sin miembros todavía'));
    }

    final auth = context.read<AuthBloc>();
    final currentUserId = auth.currentUser?.id;
    // El usuario es admin si coincide con el admin del grupo del widget
    // OJO: group.adminId a veces viene vacío si el detalle no lo trajo completo, 
    // mejor verificar rol en la lista de miembros si existe, o usar la lógica group.isAdmin
    final isPageViewerAdmin = widget.group.isAdmin(currentUserId ?? '');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final member = _members[index];
        final isMemberAdmin = member.role == GroupRole.admin;
        final display = (member.userName.isNotEmpty) ? member.userName : member.userId;
        final initial = display.isNotEmpty ? display.substring(0, 1).toUpperCase() : '?';
        
        // Habilitar borrado solo si:
        // 1. Yo soy admin (isPageViewerAdmin)
        // 2. El miembro objetivo NO es admin (no puedo borrar a otro admin ni a mí mismo por esta vía, suele ser salir)
        // 3. El miembro objetivo NO soy yo mismo (si fuera member, me salgo con leave, no remove)
        final canManage = isPageViewerAdmin && !isMemberAdmin && (member.userId != currentUserId);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFFF6F6F6),
          leading: CircleAvatar(
            backgroundColor: Colors.blueGrey[100],
            child: Text(initial),
          ),
          title: Text(display),
          subtitle: Text('Rol: ${member.role.value}', style: const TextStyle(color: Colors.black54)),
          trailing: isMemberAdmin
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Admin', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
                )
              : (canManage 
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'transfer') _transferAdmin(member.userId, display);
                        if (value == 'remove') _removeMember(member.userId, display);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'transfer',
                          child: Row(
                            children: [
                              Icon(Icons.security, size: 20, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Hacer Admin'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                    )
                  : null),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _members.length,
    );
  }
}
