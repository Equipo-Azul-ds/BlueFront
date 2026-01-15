import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../blocs/auth_bloc.dart';

/// Listens for session-expiry signals from AuthBloc and prompts the user.
class SessionExpiryListener extends StatefulWidget {
  final Widget child;
  const SessionExpiryListener({super.key, required this.child});

  @override
  State<SessionExpiryListener> createState() => _SessionExpiryListenerState();
}

class _SessionExpiryListenerState extends State<SessionExpiryListener> {
  int _lastTick = 0;
  bool _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return Selector<AuthBloc, int>(
      selector: (_, bloc) => bloc.sessionExpiryTick,
      builder: (ctx, tick, child) {
        if (tick != _lastTick && !_dialogOpen) {
          _lastTick = tick;
          WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog(ctx));
        }
        return child!;
      },
      child: widget.child,
    );
  }

  Future<void> _showDialog(BuildContext ctx) async {
    final auth = ctx.read<AuthBloc>();
    if (!auth.sessionExpiring) return;
    _dialogOpen = true;
    final result = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tu sesión está por expirar'),
        content: const Text(
          'Han pasado casi 24 horas. ¿Quieres mantener la sesión activa o cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cerrar sesión'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Seguir jugando'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (result == true) {
      try {
        await auth.refreshSession();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('No se pudo renovar la sesión: $e')),
        );
      }
    } else if (result == false) {
      await auth.logout();
      if (!mounted) return;
      Navigator.of(ctx).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }
}
