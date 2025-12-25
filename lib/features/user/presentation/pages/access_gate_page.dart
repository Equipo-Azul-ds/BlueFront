import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_welcome_page.dart';
import '../blocs/auth_bloc.dart';
import '../../../../core/constants/colors.dart';

/// Simple gate that can show loading, error, or route to welcome.
class AccessGatePage extends StatefulWidget {
  const AccessGatePage({super.key});

  @override
  State<AccessGatePage> createState() => _AccessGatePageState();
}

class _AccessGatePageState extends State<AccessGatePage> {
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final auth = context.read<AuthBloc>();
    try {
      await auth.loadSession();
      setState(() {
        _loading = false;
        _error = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        // Si falla la sesión (401/timeout), deja pasar a onboarding en lugar de bloquear.
        _error = false;
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

    return const OnboardingWelcomePage();
  }
}
