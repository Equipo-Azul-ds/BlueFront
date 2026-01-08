import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/Group.dart';
import '../../presentation/blocs/groups_bloc.dart';
import 'group_members_page.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Group? _group;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final groupId = ModalRoute.of(context)?.settings.arguments as String?;
    if (groupId == null) {
      setState(() {
        _error = 'Grupo no encontrado';
        _loading = false;
      });
      return;
    }
    final bloc = context.read<GroupsBloc>();
    final refreshed = await bloc.refreshGroup(groupId);
    Group? existing;
    try {
      existing = bloc.groups.firstWhere((g) => g.id == groupId);
    } catch (_) {}
    setState(() {
      _group = refreshed ?? existing;
      _loading = false;
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
    final group = _group;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(group?.name ?? 'Grupo', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Colors.black87),
            onPressed: group == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupMembersPage(group: group),
                      ),
                    ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) async {
              if (value == 'leave' && group != null) {
                await bloc.leaveGroup(group.id);
                if (mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'leave',
                child: Text('Salir del grupo'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Colors.black87,
          tabs: const [
            Tab(text: 'Actividad'),
            Tab(text: 'Compartido'),
            Tab(text: 'Asignaciones'),
          ],
        ),
      ),
      body: _buildBody(bloc),
    );
  }

  Widget _buildBody(GroupsBloc bloc) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _group == null) {
      return Center(child: Text(_error ?? 'No se pudo cargar el grupo'));
    }
    final group = _group!;
    return TabBarView(
      controller: _tabController,
      children: [
        _activityTab(group),
        _sharedTab(),
        _assignmentsTab(),
      ],
    );
  }

  Widget _activityTab(Group group) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Miembros', '${group.members.length}'),
        const SizedBox(height: 8),
        _infoRow('Admin', group.adminId),
        const SizedBox(height: 24),
        _placeholderCard(
          title: 'Sin actividad todavía',
          message: 'Comparte algo en el grupo para comenzar el feed.',
          icon: Icons.chat_bubble_outline,
        ),
      ],
    );
  }

  Widget _sharedTab() {
    return Center(
      child: _placeholderCard(
        title: 'Comparte Kahoots',
        message: 'Aquí verás los kahoots compartidos dentro del grupo.',
        icon: Icons.folder_shared_outlined,
      ),
    );
  }

  Widget _assignmentsTab() {
    return Center(
      child: _placeholderCard(
        title: 'Sin asignaciones',
        message: 'Asigna kahoots al grupo y aparecerán aquí.',
        icon: Icons.task_outlined,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _placeholderCard({required String title, required String message, required IconData icon}) {
    return Card(
      color: const Color(0xFFF6F6F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
