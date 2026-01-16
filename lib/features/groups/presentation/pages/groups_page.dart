import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/Group.dart';
import '../../presentation/blocs/groups_bloc.dart';
import 'group_detail_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsBloc>().loadMyGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<GroupsBloc>();

    final owned = bloc.ownedGroups();
    final joined = bloc.joinedGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Propios'),
            Tab(text: 'Unidos'),
          ],
        ),
      ),
      body: bloc.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bloc.groups.isNotEmpty
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _groupsList(owned),
                    _groupsList(joined),
                  ],
                )
              : bloc.error != null
                  ? Center(child: Text(bloc.error!, textAlign: TextAlign.center))
                  : const Center(child: Text('Aún no tienes grupos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrJoinSheet(context),
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _groupsList(List<Group> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Aún no hay grupos para mostrar'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _groupCard(items[index]),
    );
  }

// (Clase movida fuera de _GroupsPageState)

  Widget _groupCard(Group group) {
    final bloc = context.read<GroupsBloc>();
    final isAdmin = bloc.isCurrentUserAdmin(group);
    final members = group.memberCount;

    return Card(
      color: const Color(0xFFF6F6F6),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text('$members miembros', style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 12),
              _roleBadge(isAdmin ? 'Admin' : 'Miembro'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const GroupDetailPage(),
              settings: RouteSettings(arguments: group.id),
            ),
          );
        },
      ),
    );
  }

  Widget _roleBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF1F4B99))),
    );
  }

  void _showCreateOrJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bloc = context.read<GroupsBloc>();

        return _CreateJoinSheet(
          bloc: bloc,
          rootContext: context,
        );
      },
    );
  }
}
// Widget separado para evitar recrear controllers al cerrar teclado/reenfocar
class _CreateJoinSheet extends StatefulWidget {
  final GroupsBloc bloc;
  final BuildContext rootContext;

  const _CreateJoinSheet({required this.bloc, required this.rootContext});

  @override
  State<_CreateJoinSheet> createState() => _CreateJoinSheetState();
}

class _CreateJoinSheetState extends State<_CreateJoinSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _tokenCtrl;
  bool isCreating = false;
  bool isJoining = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _tokenCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    Future<void> handleCreate() async {
      final text = _nameCtrl.text.trim();
      if (text.isEmpty) return;
      setState(() => isCreating = true);
      try {
        await widget.bloc.createGroup(text);
        if (mounted) {
          Navigator.pop(widget.rootContext);
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            const SnackBar(content: Text('Grupo creado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            const SnackBar(content: Text('No se pudo crear el grupo. Intenta más tarde.')),
          );
        }
      } finally {
        if (mounted) setState(() => isCreating = false);
      }
    }

    Future<void> handleJoin() async {
      final input = _tokenCtrl.text.trim();
      if (input.isEmpty) return;
      // Permitir pegar el link completo o solo el token.
      String token = input;
      try {
        final uri = Uri.parse(input);
        if (uri.scheme.isNotEmpty) {
          // Primero buscar en query parameters
          if (uri.queryParameters.containsKey('token')) {
            token = uri.queryParameters['token']!;
          } else if (uri.queryParameters.containsKey('invitationToken')) {
            token = uri.queryParameters['invitationToken']!;
          } else if (uri.pathSegments.isNotEmpty) {
            // Si no hay query param, usar el último segmento del path
            token = uri.pathSegments.last;
          }
        } else {
          // Si no es un URI completo, intentar dividir por '/'
          final parts = input.split('/');
          token = parts.isNotEmpty ? parts.last : input;
        }
        token = token.replaceAll('"', '').replaceAll("'", '').trim();
      } catch (_) {
        // Si parse falla, usar input tal cual
        token = input;
      }
      
      // Validación preventiva: si el token extraído es palabras reservadas del path comun
      if (token.toLowerCase() == 'join' || token.toLowerCase() == 'groups') {
         if (mounted) {
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(
                content: Text('Error: El link no contiene un token válido (se detectó "$token"). Asegúrate de copiar el link de invitación completo.'),
                backgroundColor: Colors.red,
              ),
            );
         }
         return;
      }

      // Log para depuración
      // ignore: avoid_print
      print('[groups] join attempt input="$input" token="$token"');
      setState(() => isJoining = true);
      try {
        await widget.bloc.joinByToken(token);
        if (mounted) {
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            const SnackBar(content: Text('Ingreso al grupo exitoso')),
          );
          Navigator.pop(widget.rootContext);
        }
      } catch (e) {
        if (mounted) {
          // Extraemos el mensaje de la excepción para ver si menciona que ya es miembro
          String msg = e.toString().replaceAll('Exception:', '').trim();
          bool alreadyMember = msg.toLowerCase().contains('already') || 
                               msg.toLowerCase().contains('ya eres miembro') ||
                               msg.toLowerCase().contains('miembro del grupo');
          
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(
              content: Text(alreadyMember ? 'Ya eres miembro de este grupo' : 'Error: $msg'),
              backgroundColor: alreadyMember ? Colors.orange : Colors.red,
            ),
          );
          // ignore: avoid_print
          print('[groups] join failed: $e');
        }
      } finally {
        if (mounted) setState(() => isJoining = false);
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add, color: Colors.black87),
              const SizedBox(width: 8),
              const Text('Crear o unirse a un grupo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Crear grupo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nombre del grupo',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => handleCreate(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCreating ? null : handleCreate,
              icon: isCreating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(isCreating ? 'Creando...' : 'Crear grupo'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Unirse con link', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Link de invitación',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => handleJoin(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isJoining ? null : handleJoin,
              icon: isJoining
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(isJoining ? 'Uniendo...' : 'Unirse'),
            ),
          ),
        ],
      ),
    );
  }
}
