import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'onboarding_welcome_page.dart';
import '../blocs/auth_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../common_pages/dashboard_page.dart';

import '../../../../local/secure_storage.dart';

/// Simple gate that can show loading, error, or route to welcome.
class AccessGatePage extends StatefulWidget {
  const AccessGatePage({super.key});

  @override
  State<AccessGatePage> createState() => _AccessGatePageState();
}

class _AccessGatePageState extends State<AccessGatePage> {
  // Inicializamos en loading=true
  bool _loading = true;
  bool _error = false;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    print('[AccessGate] initState - scheduling check');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkSession();
      }
    });
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final auth = context.read<AuthBloc>();
    
    // 1. Verificación rápida local: ¿Tenemos token?
    // Esto evita llamar a auth.loadSession() (que notifica listeners) si ni siquiera hay token.
    final token = await SecureStorage.instance.read('token');
    if (token == null) {
      if (!mounted) return;
      // Si no hay token, cortamos flujo inmediatamente.
      setState(() {
         _loading = false;
         _error = false;
         _hasSession = false;
      });
      return;
    }

    try {
      // 2. Si hay token, intentamos cargar la sesión completa
      print('[AccessGate] Token found, calling auth.loadSession()...');
      await auth.loadSession().timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = false;
        _hasSession = auth.currentUser != null;
      });
    } catch (e) {
      print('[AccessGate] Error checking session: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = false; 
        _hasSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColor.primary,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error) {
      return Scaffold(
        backgroundColor: AppColor.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColor.primary),
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = false;
                  });
                  _checkSession();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasSession) {
      return const DashboardPage();
    }

    return const OnboardingWelcomePage();
  }
}
