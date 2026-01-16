import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/Group.dart';
import '../../presentation/blocs/groups_bloc.dart';
import 'group_members_page.dart';
import '../../../user/presentation/blocs/auth_bloc.dart';
import '../../domain/entities/GroupInvitationToken.dart';
import '../../../kahoot/domain/repositories/QuizRepository.dart';
import '../../../kahoot/domain/entities/Quiz.dart';

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
  GroupInvitationToken? _invite;
  bool _inviteLoading = false;
  Future<void>? _assignmentsFuture;
  bool _assignmentsFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final isAdmin = _isCurrentUserAdmin(context, group);
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
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.link, color: Colors.black87),
              onPressed: _inviteLoading ? null : () => _generateInvite(bloc, group),
              tooltip: 'Generar invitación',
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black87),
              tooltip: 'Editar grupo',
              onPressed: group == null ? null : () => _showEditGroupDialog(bloc, group),
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
            Tab(text: 'Asignaciones'),
          ],
        ),
      ),
      body: _buildBody(bloc),
      floatingActionButton: (group != null && _isCurrentUserMember(context, group))
          ? FloatingActionButton.extended(
              onPressed: () => _showAssignQuizDialog(bloc, group),
              icon: const Icon(Icons.assignment_add),
              label: const Text('Asignar quiz'),
            )
          : null,
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
    final adminLabel = _adminDisplayName(context, group);
    return TabBarView(
      controller: _tabController,
      children: [
        _activityTab(group, adminLabel),
        _assignmentsTab(bloc),
      ],
    );
  }

  bool _isCurrentUserAdmin(BuildContext context, Group? group) {
    if (group == null) return false;
    final auth = context.read<AuthBloc>();
    return auth.currentUser?.id == group.adminId;
  }

  bool _isCurrentUserMember(BuildContext context, Group? group) {
    if (group == null) return false;
    final auth = context.read<AuthBloc>();
    final uid = auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return false;
    return group.isMember(uid);
  }

  String _adminDisplayName(BuildContext context, Group group) {
    final auth = context.read<AuthBloc>();
    final current = auth.currentUser;
    if (current != null && current.id == group.adminId) {
      return current.userName.isNotEmpty ? current.userName : (current.email.isNotEmpty ? current.email : group.adminId);
    }
    return group.adminId;
  }

  Widget _activityTab(Group group, String adminLabel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Miembros', '${group.members.length}'),
        const SizedBox(height: 8),
        _infoRow('Admin', adminLabel),
        if ((group.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoRow('Descripción', group.description ?? ''),
        ],
        const SizedBox(height: 12),
        if (_invite != null)
          _inviteCard(_invite!),
        const SizedBox(height: 24),
        _placeholderCard(
          title: 'Sin actividad todavía',
          message: 'Comparte algo en el grupo para comenzar el feed.',
          icon: Icons.chat_bubble_outline,
        ),
      ],
    );
  }

  Widget _inviteCard(GroupInvitationToken invite) {
    final linkText = invite.link.isNotEmpty ? invite.link : invite.token;
    return Card(
      color: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.link, color: Colors.green),
                SizedBox(width: 8),
                Text('Invitación generada', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCCE8D8)),
              ),
              child: SelectableText(
                linkText,
                style: const TextStyle(color: Colors.black87, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar enlace'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: linkText));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enlace copiado al portapapeles')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp'),
                    onPressed: () => _shareWhatsApp(linkText),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sms, size: 18),
                    label: const Text('SMS'),
                    onPressed: () => _shareSMS(linkText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Expira: ${invite.expiresAt.toLocal()}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _shareWhatsApp(String link) async {
    final text = Uri.encodeComponent('Únete al grupo: $link');
    final uri = Uri.parse('https://wa.me/?text=$text');
    await _launchExternal(uri);
  }

  Future<void> _shareSMS(String link) async {
    final uri = Uri(scheme: 'sms', queryParameters: {'body': 'Únete al grupo: $link'});
    await _launchExternal(uri);
  }

  Future<void> _launchExternal(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app para compartir')),
      );
    }
  }

  Future<void> _generateInvite(GroupsBloc bloc, Group? group) async {
    if (group == null) return;
    setState(() {
      _inviteLoading = true;
    });
    try {
      final token = await bloc.generateInvitation(group.id);
      setState(() {
        _invite = token;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitación generada')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar la invitación: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _inviteLoading = false;
        });
      }
    }
  }

  Future<void> _showEditGroupDialog(GroupsBloc bloc, Group group) async {
    final nameCtrl = TextEditingController(text: group.name);
    final descCtrl = TextEditingController(text: group.description ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar grupo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final newName = nameCtrl.text.trim();
      final newDesc = descCtrl.text.trim();

      if (newName.isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('El nombre no puede estar vacío')),
           );
        }
        return;
      }
      
      setState(() => _loading = true); // Bloquear UI mientras guarda
      
      try {
        await bloc.updateGroupInfo(
            groupId: group.id,
            name: newName,
            description: newDesc
        );
        setState(() => _loading = false);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Grupo actualizado')),
           );
           // Recargar para refrescar campos
           _load(); 
        }
      } catch (e) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: $e')),
          );
        }
      }
    }
  }

  Widget _assignmentsTab(GroupsBloc bloc) {
    _assignmentsFuture ??= _ensureAssignmentsLoaded(bloc);

    return FutureBuilder<void>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        final group = _group;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (group == null) {
          return Center(
            child: _placeholderCard(
              title: 'Sin datos del grupo',
              message: 'No se pudo cargar el grupo.',
              icon: Icons.error_outline,
            ),
          );
        }

        final assignments = group.quizAssignments;
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _placeholderCard(
                  title: 'Sin asignaciones',
                  message: 'Asigna kahoots al grupo y aparecerán aquí.',
                  icon: Icons.task_outlined,
                ),
                const SizedBox(height: 12),
                if (_isCurrentUserMember(context, group))
                  ElevatedButton.icon(
                    onPressed: () => _showAssignQuizDialog(context.read<GroupsBloc>(), group),
                    icon: const Icon(Icons.assignment_add),
                    label: const Text('Asignar quiz'),
                  ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final a = assignments[i];
            final availableUntilStr = _fmt(a.availableUntil.toLocal());
            final availableFromStr = _fmt(a.availableFrom.toLocal());
            final title = a.quizTitle.isNotEmpty ? a.quizTitle : a.quizId;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Asignación de Quiz', style: TextStyle(fontWeight: FontWeight.w700)),
                        Icon(a.isActive ? Icons.check_circle : Icons.cancel, color: a.isActive ? Colors.green : Colors.red, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Quiz: $title', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Disponible desde: $availableFromStr', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('Disponible hasta: $availableUntilStr', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  Future<void> _showAssignQuizDialog(GroupsBloc bloc, Group group) async {
    final auth = context.read<AuthBloc>();
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }

    // Cargar quizzes del usuario
    List<Quiz> myQuizzes = [];
    try {
      final repo = context.read<QuizRepository>();
      myQuizzes = await repo.searchByAuthor(userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudieron cargar tus quizzes: $e')));
      return;
    }

    if (myQuizzes.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sin quizzes propios'),
          content: const Text('Crea un quiz primero para poder asignarlo.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          ],
        ),
      );
      return;
    }

    Quiz? selected;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: const Text('Asignar quiz al grupo', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<Quiz>(
                      decoration: const InputDecoration(
                        labelText: 'Selecciona un quiz',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: myQuizzes
                          .map((q) => DropdownMenuItem<Quiz>(
                                value: q,
                                child: Text(
                                  q.title,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ))
                          .toList(),
                      onChanged: (q) => setState(() => selected = q),
                      value: selected,
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDate == null
                            ? 'Elegir fecha límite'
                            : 'Fecha: ${selectedDate!.toLocal().toString().split(' ').first}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Hasta cuándo estará disponible'),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        selectedTime == null
                            ? 'Elegir hora límite'
                            : 'Hora: ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Hora exacta de cierre'),
                      onTap: () async {
                        final now = TimeOfDay.now();
                        final picked = await showTimePicker(context: ctx, initialTime: selectedTime ?? now);
                        if (picked != null) setState(() => selectedTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Asignar')),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    if (selected == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona quiz, fecha y hora')));
      return;
    }

    final availableUntilLocal = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    final availableUntilUtc = availableUntilLocal.toUtc();

    try {
      final assignment = await bloc.repository.assignQuizToGroup(
        groupId: group.id,
        quizId: selected!.quizId,
        availableUntil: availableUntilUtc,
      );
      // Refrescar grupo para ver la asignación
      final refreshed = await bloc.refreshGroup(group.id);
      setState(() {
        final currentAssignments = (refreshed ?? _group)?.quizAssignments ?? [];
        final merged = [...currentAssignments, assignment];
        _group = (refreshed ?? _group)?.copyWith(quizAssignments: merged) ?? _group;
        _assignmentsFetched = false; // allow future reload if needed
        _assignmentsFuture = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz asignado hasta ${assignment.availableUntil.toLocal()}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo asignar: $e')));
    }
  }

  Future<void> _ensureAssignmentsLoaded(GroupsBloc bloc) async {
    if (_assignmentsFetched || _group == null) return;
    try {
      final refreshed = await bloc.refreshGroup(_group!.id);
      // Además de refrescar el grupo completo, intenta obtener asignaciones del endpoint dedicado.
      try {
        await bloc.loadGroupAssignments(_group!.id);
      } catch (_) {
        // si falla, al menos mantenemos el detalle cargado
      }
      setState(() {
        final latest = bloc.groups.firstWhere(
          (g) => g.id == _group!.id,
          orElse: () => refreshed ?? _group!,
        );
        _group = latest;
        _assignmentsFetched = true;
      });
    } catch (_) {
      // Silently ignore; UI will show placeholder error card.
    }
  }

  String _fmt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
