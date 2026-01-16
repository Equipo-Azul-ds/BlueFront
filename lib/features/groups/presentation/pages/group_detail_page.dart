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
    
    // 1. Obtener versión local primero (Optimistic UI)
    Group? existing;
    try {
      existing = bloc.groups.firstWhere((g) => g.id == groupId);
    } catch (_) {}

    // 2. Intentar refrescar desde la red
    final refreshed = await bloc.refreshGroup(groupId);
    
    if (mounted) {
      setState(() {
        _group = refreshed ?? existing;
        _loading = false;
        if (_group == null) {
          _error = 'No se pudo cargar la información del grupo';
        }
      });
    }
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
              if (group == null) return;
              if (value == 'leave') {
                 // Confirmar salir
                 final confirm = await showDialog<bool>(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     title: const Text('Salir del grupo'),
                     content: const Text('¿Estás seguro de salir? No podrás volver a entrar sin invitación.'),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                       TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir', style: TextStyle(color: Colors.red))),
                     ],
                   ),
                 );
                 if (confirm == true) {
                    await bloc.leaveGroup(group.id);
                    if (mounted) Navigator.pop(context);
                 }
              }
              if (value == 'delete') {
                _confirmDeleteGroup(bloc, group);
              }
            },
            itemBuilder: (context) {
              if (isAdmin) {
                return [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar grupo', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              } else {
                return [
                  const PopupMenuItem<String>(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.black87),
                        SizedBox(width: 8),
                        Text('Salir del grupo'),
                      ],
                    ),
                  ),
                ];
              }
            },
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
      floatingActionButton: (group != null && isAdmin)
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
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return false;
    return group.isAdmin(userId);
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
    // Si somos admin (por rol o id), mostramos nuestro nombre
    if (current != null && group.isAdmin(current.id)) {
      return current.userName.isNotEmpty ? current.userName : (current.email.isNotEmpty ? current.email : 'Tú');
    }
    // Si no, fallback al adminId
    return group.adminId.isNotEmpty ? group.adminId : 'Admin';
  }

  Widget _activityTab(Group group, String adminLabel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Usar memberCount para respetar el snapshot del listado
        _infoRow('Miembros', '${group.memberCount}'),
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

  Future<void> _confirmDeleteGroup(GroupsBloc bloc, Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este grupo permanentemente?\n\n'
          'Esta acción no se puede deshacer y se perderán todos los datos y asignaciones asociadas.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await bloc.deleteGroup(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grupo eliminado exitosamente')),
          );
          Navigator.pop(context); // Volver a la lista
        }
      } catch (e) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
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
                if (_isCurrentUserAdmin(context, group))
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

    Quiz? selectedQuiz;
    DateTime? startDate;
    TimeOfDay? startTime;
    DateTime? endDate;
    TimeOfDay? endTime;

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
                      onChanged: (val) { 
                        setState(() {
                          selectedQuiz = val;
                        });
                      },
                      value: selectedQuiz,
                    ),
                    const SizedBox(height: 14),
                    const Text('Disponible desde:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: startDate ?? now,
                                firstDate: now,
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) setState(() => startDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Fecha Inicio'),
                              child: Text(startDate == null ? '-' : startDate!.toLocal().toString().split(' ').first),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = TimeOfDay.now();
                              final picked = await showTimePicker(context: ctx, initialTime: startTime ?? now);
                              if (picked != null) setState(() => startTime = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Hora Inicio'),
                              child: Text(startTime == null ? '-' : startTime!.format(ctx)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Disponible hasta:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: endDate ?? now,
                                firstDate: now,
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) setState(() => endDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Fecha Fin'),
                              child: Text(endDate == null ? '-' : endDate!.toLocal().toString().split(' ').first),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = TimeOfDay.now();
                              final picked = await showTimePicker(context: ctx, initialTime: endTime ?? now);
                              if (picked != null) setState(() => endTime = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Hora Fin'),
                              child: Text(endTime == null ? '-' : endTime!.format(ctx)),
                            ),
                          ),
                        ),
                      ],
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

    if (selectedQuiz == null || startDate == null || startTime == null || endDate == null || endTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa todos los campos de fecha y hora.')));
      }
      return;
    }

    final startDateTime = DateTime(
      startDate!.year, startDate!.month, startDate!.day,
      startTime!.hour, startTime!.minute,
    );
    
    final endDateTime = DateTime(
      endDate!.year, endDate!.month, endDate!.day,
      endTime!.hour, endTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La fecha de fin debe ser posterior a la de inicio.')));
      }
      return;
    }

    try {
      await bloc.assignQuiz(
        groupId: group.id,
        quizId: selectedQuiz!.quizId,
        availableFrom: startDateTime.toUtc(),
        availableUntil: endDateTime.toUtc(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz asignado exitosamente')));
        // Forzar recarga de asignaciones
        await _ensureAssignmentsLoaded(bloc); 
        setState(() {
          _assignmentsFetched = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo asignar: $e')));
      }
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
