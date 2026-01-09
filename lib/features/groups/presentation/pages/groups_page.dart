import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Grupos', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () => _showCreateOrJoinSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Colors.black87,
          tabs: const [
            Tab(text: 'Unidos'),
            Tab(text: 'Propios'),
          ],
        ),
      ),
      body: _buildBody(bloc),
    );
  }

  Widget _buildBody(GroupsBloc bloc) {
    if (bloc.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bloc.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No pudimos cargar tus grupos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                Text(
                  bloc.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: bloc.loadMyGroups,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final joined = bloc.joinedGroups();
    final owned = bloc.ownedGroups();

    return TabBarView(
      controller: _tabController,
      children: [
        _groupList(
          joined,
          emptyTitle: 'No te has unido a ningún grupo',
          emptySubtitle: 'Únete con un código de invitación.',
        ),
        _groupList(
          owned,
          emptyTitle: 'Aún no creas grupos',
          emptySubtitle: 'Crea un grupo y comienza a colaborar.',
        ),
      ],
    );
  }

  Widget _groupList(List<Group> groups, {required String emptyTitle, required String emptySubtitle}) {
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_outlined, size: 48, color: Colors.black45),
              const SizedBox(height: 12),
              Text(emptyTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(emptySubtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final g = groups[index];
        return _groupCard(g);
      },
    );
  }

  Widget _groupCard(Group group) {
    final bloc = context.read<GroupsBloc>();
    final isAdmin = bloc.isCurrentUserAdmin(group);
    final members = group.members.length;

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
        final nameCtrl = TextEditingController();
        final tokenCtrl = TextEditingController();
        final bloc = context.read<GroupsBloc>();

        bool isCreating = false;
        bool isJoining = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleCreate() async {
              final text = nameCtrl.text.trim();
              if (text.isEmpty) return;
              setState(() => isCreating = true);
              try {
                await bloc.createGroup(text);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo crear el grupo. Intenta más tarde.')),
                  );
                }
              } finally {
                if (mounted) setState(() => isCreating = false);
              }
            }

            Future<void> handleJoin() async {
              final text = tokenCtrl.text.trim();
              if (text.isEmpty) return;
              setState(() => isJoining = true);
              try {
                await bloc.joinByToken(text);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo unir al grupo. Verifica el código.')),
                  );
                }
              } finally {
                if (mounted) setState(() => isJoining = false);
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Acciones rápidas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Crear grupo', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameCtrl,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del grupo',
                              hintText: 'Ej. Matemáticas 2026',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => handleCreate(),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isCreating ? null : handleCreate,
                              child: isCreating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Crear'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unirse con código', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: tokenCtrl,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Token de invitación',
                              hintText: 'Pega el código que te compartieron',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => handleJoin(),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isJoining ? null : handleJoin,
                              child: isJoining
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Unirse'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
