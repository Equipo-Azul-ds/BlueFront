import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/entities/User.dart';
import '../blocs/auth_bloc.dart';
import 'avatar_picker_page.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../pages/access_gate_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameCtrl;
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  late String _type;
  bool _libraryLoaded = false;
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _nameCtrl.addListener(() => setState(() {}));
    _type = widget.user.userType;
    _avatarUrl = widget.user.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const AvatarPickerPage()),
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _avatarUrl = picked);
      try {
        final auth = context.read<AuthBloc>();
        await _ensureHashThen(auth, () async {
          await auth.updateProfile(avatarUrl: picked);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar actualizado')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el avatar: $e')),
        );
      }
    }
  }

  Future<void> _ensureHashThen(AuthBloc auth, Future<void> Function() action) async {
    // Si ya tenemos hash, simplemente ejecuta la acción.
    final hasHash = (auth.currentUser?.hashedPassword.isNotEmpty ?? false);
    if (hasHash) {
      await action();
      return;
    }
    // Solicita contraseña en una hoja modal.
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final passCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Confirma tu contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final p = passCtrl.text.trim();
                  if (p.length < 6) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Min. 6 caracteres')),
                    );
                    return;
                  }
                  try {
                    await auth.providePasswordForValidation(p);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('No se pudo validar: $e')),
                    );
                  }
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
    if (ok == true) {
      await action();
    } else {
      throw Exception('Se requiere confirmar contraseña para continuar');
    }
  }

  Widget _securitySection(AuthBloc auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Seguridad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final newP = _newPassCtrl.text;
                    final conf = _confirmPassCtrl.text;
                    if (newP.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                      );
                      return;
                    }
                    if (newP != conf) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Las contraseñas no coinciden')),
                      );
                      return;
                    }
                    try {
                      await auth.changePassword(newP);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contraseña actualizada')),
                      );
                      _newPassCtrl.clear();
                      _confirmPassCtrl.clear();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo actualizar: $e')),
                      );
                    }
                  },
            child: const Text('Restablecer contraseña'),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _nameCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>();
    final user = auth.currentUser ?? widget.user;
    final library = context.watch<LibraryProvider>();

    // Cargar listas de biblioteca del usuario para los contadores de actividad
    if (!_libraryLoaded && user.id.isNotEmpty) {
      _libraryLoaded = true;
      // post-frame para evitar setState en build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        library.loadAllLists(user.id);
      });
    }
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColor.primary,
        actions: [
          TextButton(
            onPressed: auth.isLoading ? null : () => _confirmLogout(auth),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(user),
              const SizedBox(height: 16),
              _statsSection(user, library),
              const SizedBox(height: 16),
              _accountSection(auth, user),
              const SizedBox(height: 16),
              _securitySection(auth),
              const SizedBox(height: 16),
              _dangerZone(auth),
            ],
          ),
        ),
      ),
    );
  }

  void _save(AuthBloc auth) async {
    try {
      await _ensureHashThen(auth, () async {
        await auth.updateProfile(
          name: _nameCtrl.text.trim(),
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Future<void> _confirmLogout(AuthBloc auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí')),
        ],
      ),
    );
    if (ok == true) {
      await auth.logout();
      if (!mounted) return;
      // Usa el Navigator raíz para reemplazar toda la app stack por la vista de bienvenida
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    }
  }

  Widget _header(User u) {
    final effectiveAvatar = _avatarUrl.isNotEmpty ? _avatarUrl : u.avatarUrl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _pickAvatar,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColor.primary,
              backgroundImage: effectiveAvatar.isNotEmpty ? NetworkImage(effectiveAvatar) : null,
              child: effectiveAvatar.isEmpty
                  ? Text(u.userName.isNotEmpty ? u.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(u.email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Tipo: ${u.userType}', style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Membresía: ${u.membership.type}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection(User u, LibraryProvider library) {
    final created = library.createdKahoots.length;
    final inProgress = library.inProgressKahoots.length;
    final completed = library.completedKahoots.length;
    final totalPlayed = inProgress + completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tu actividad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _StatCard(label: 'Kahoots creados', value: created.toString()),
              _StatCard(label: 'En progreso', value: inProgress.toString()),
              _StatCard(label: 'Completados', value: completed.toString()),
              _StatCard(label: 'Partidas jugadas', value: totalPlayed.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountSection(AuthBloc auth, User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tu cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tipo de cuenta'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Estudiante'),
                selected: (_type.isNotEmpty ? _type : user.userType) == 'student',
                onSelected: auth.isLoading
                    ? null
                    : (sel) async {
                        if (!sel) return;
                        setState(() => _type = 'student');
                        try {
                          await _ensureHashThen(auth, () async {
                            await auth.changeUserType('student');
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tipo de cuenta: Estudiante')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No se pudo actualizar: $e')),
                          );
                        }
                      },
              ),
              ChoiceChip(
                label: const Text('Profesor'),
                selected: (_type.isNotEmpty ? _type : user.userType) == 'teacher',
                onSelected: auth.isLoading
                    ? null
                    : (sel) async {
                        if (!sel) return;
                        setState(() => _type = 'teacher');
                        try {
                          await _ensureHashThen(auth, () async {
                            await auth.changeUserType('teacher');
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tipo de cuenta: Profesor')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No se pudo actualizar: $e')),
                          );
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (ctx) {
            final nameChanged = _nameCtrl.text.trim() != user.name;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
              onPressed: (auth.isLoading || !nameChanged) ? null : () => _save(auth),
              child: auth.isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar cambios'),
            );
          }),
        ],
      ),
    );
  }

  Widget _dangerZone(AuthBloc auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Opciones de cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar cuenta'),
                        content: const Text('¿Estás seguro de eliminar tu cuenta de forma permanente?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      try {
                        await auth.deleteAccount();
                        if (!mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil('/discover', (route) => false);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('No se pudo eliminar la cuenta: $e')));
                      }
                    }
                  },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
