import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/Group.dart';
import '../../domain/entities/GroupMember.dart';
import '../../domain/entities/GroupRole.dart';
import '../blocs/groups_bloc.dart';

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
      setState(() {
        _members = refreshed ?? _members;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los miembros';
        _loading = false;
      });
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final member = _members[index];
        final isAdmin = member.role == GroupRole.admin;
        final display = (member.userName.isNotEmpty) ? member.userName : member.userId;
        final initial = display.isNotEmpty ? display.substring(0, 1).toUpperCase() : '?';
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
          trailing: isAdmin
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Admin', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
                )
              : null,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _members.length,
    );
  }
}
