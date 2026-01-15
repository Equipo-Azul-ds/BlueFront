import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/entities/User.dart';
import '../blocs/auth_bloc.dart';
import 'avatar_picker_page.dart';
import '../../../library/presentation/providers/library_provider.dart';
import 'package:Trivvy/features/subscriptions/presentation/provider/subscription_provider.dart';
import 'package:Trivvy/features/subscriptions/presentation/screens/plans_screen.dart';
import 'package:Trivvy/features/subscriptions/presentation/widgets/plan_badge.dart';
import 'package:Trivvy/features/subscriptions/presentation/screens/subscription_management_screen.dart';
import '../pages/access_gate_page.dart';
import '../../../report/presentation/pages/reports_list_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameCtrl;
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  late String _type;
  bool _libraryLoaded = false;
  String _avatarUrl = '';
  static const String adminRoute = '/admin';
  static const String notificationsHistoryRoute = '/notifications-history';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _nameCtrl.addListener(() => setState(() {}));
    _descCtrl.text = widget.user.description;
    _type = widget.user.userType;
    _avatarUrl = widget.user.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    final picked = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const AvatarPickerPage()));
    if (picked != null && picked.isNotEmpty) {
      // Construye la URL del avatar a partir del seed seleccionado
      final avatarUrl = 'https://api.dicebear.com/7.x/micah/png?seed=$picked&background=%23ffffff&size=128';
      setState(() => _avatarUrl = avatarUrl);
    }
  }

  Future<void> _ensureHashThen(
    AuthBloc auth,
    Future<void> Function() action,
  ) async {
    // Ya no se requiere validar hash para guardar perfil; ejecuta la acción.
    await action();
  }

  Widget _securitySection(AuthBloc auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Seguridad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
                        const SnackBar(
                          content: Text(
                            'La contraseña debe tener al menos 6 caracteres',
                          ),
                        ),
                      );
                      return;
                    }
                    if (newP != conf) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Las contraseñas no coinciden'),
                        ),
                      );
                      return;
                    }
                    // Solicita contraseña actual antes de enviar el cambio.
                    final current = await showModalBottomSheet<String?>(
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
                              const Text(
                                'Ingresa tu contraseña actual',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: passCtrl,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña actual',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  final p = passCtrl.text.trim();
                                  if (p.length < 6) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Min. 6 caracteres')),
                                    );
                                    return;
                                  }
                                  Navigator.pop(ctx, p);
                                },
                                child: const Text('Continuar'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    if (current == null) return;
                    try {
                      await auth.changePassword(currentPassword: current, newPassword: newP, confirmNewPassword: conf);
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
    _descCtrl.dispose();
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

    // Usamos el ID real para cargar la suscripción si no está cargada
    if (user.id.isNotEmpty) {
      final subProvider = context.read<SubscriptionProvider>();
      if (subProvider.status == SubscriptionStatus.initial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          subProvider.checkCurrentStatus(user.id);
        });
      }
    }
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColor.primary,
        actions: [
          TextButton(
            onPressed: auth.isLoading ? null : () => _confirmLogout(auth),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white),
            ),
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
              _subscriptionSection(context),
              const SizedBox(height: 16),
              _securitySection(auth),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, notificationsHistoryRoute),
                icon: const Icon(Icons.history),
                label: const Text('Historial de Notificaciones'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportsListPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.assessment),
                label: const Text('Informes y Estadísticas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(adminRoute),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ir a Página de Administrador'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _save(AuthBloc auth) async {
    try {
      final nameVal = _nameCtrl.text.trim();
      final descVal = _descCtrl.text.trim();
      final avatarChanged = _avatarUrl.isNotEmpty && _avatarUrl != (auth.currentUser?.avatarUrl ?? widget.user.avatarUrl);

      // Use currentUser values if form fields are empty
      final name = nameVal.isNotEmpty ? nameVal : (auth.currentUser?.name ?? '');
      final description = descVal.isNotEmpty ? descVal : (auth.currentUser?.description ?? '');

      await auth.updateProfile(
        name: name,
        description: description,
        avatarUrl: avatarChanged ? _avatarUrl : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil guardado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Future<void> _confirmLogout(AuthBloc auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await auth.logout();
      if (!mounted) return;
      // Usa el Navigator raíz para reemplazar toda la app stack por la vista de bienvenida
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
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
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              backgroundImage: effectiveAvatar.isNotEmpty
                  ? NetworkImage(effectiveAvatar)
                  : null,
              child: effectiveAvatar.isEmpty
                  ? Text(
                      u.userName.isNotEmpty ? u.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(u.email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tipo: ${u.userType}',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const PlanBadge(),
                  ],
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu actividad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _StatCard(label: 'Kahoots creados', value: created.toString()),
              _StatCard(label: 'En progreso', value: inProgress.toString()),
              _StatCard(label: 'Completados', value: completed.toString()),
              _StatCard(
                label: 'Partidas jugadas',
                value: totalPlayed.toString(),
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tu cuenta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) {
              final nameChanged = _nameCtrl.text.trim() != user.name;
              final descChanged = _descCtrl.text.trim() != user.description;
              final avatarChanged = _avatarUrl.isNotEmpty && _avatarUrl != user.avatarUrl;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: (auth.isLoading || (!nameChanged && !descChanged && !avatarChanged))
                    ? null
                    : () => _save(auth),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar cambios'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _subscriptionSection(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isPremium = subProvider.isPremium;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPremium ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPremium
            ? Border.all(color: Colors.amber.shade300, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.star_outline,
                color: isPremium ? Colors.amber.shade800 : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                isPremium ? 'Suscripción Premium' : 'Suscripción',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPremium
                ? 'Disfrutas de todas las ventajas de Premium.'
                : 'Accede a funciones exclusivas creando y jugando sin límites.',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isPremium
                      ? const SubscriptionManagementScreen()
                      : const PlansScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium
                  ? Colors.amber.shade700
                  : AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isPremium ? 'Gestionar suscripción' : 'Ver planes Premium',
            ),
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
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
