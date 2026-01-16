import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/config/api_config.dart';
import '../../../../main.dart';
import 'login_page.dart';
import 'account_type_page.dart';

class OnboardingWelcomePage extends StatefulWidget {
  const OnboardingWelcomePage({super.key});

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage> {
  late final ConfettiController _confettiController;
  Timer? _heroTimer;
  int _heroIndex = 0;

  final List<_HeroItem> _heroItems = const [
    _HeroItem(icon: Icons.celebration, title: 'Crea retos únicos'),
    _HeroItem(icon: Icons.games, title: 'Juega en vivo con amigos'),
    _HeroItem(icon: Icons.star, title: 'Gana streaks y recompensas'),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3))..play();
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _heroIndex = (_heroIndex + 1) % _heroItems.length;
      });
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = _heroItems[_heroIndex];
    return Scaffold(
      backgroundColor: AppColor.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0D47A1),
                            Color(0xFF1565C0),
                            Color(0xFF1976D2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                        child: Column(
                          children: [
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                key: ValueKey(hero.icon),
                                height: 220,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(hero.icon, color: Colors.white, size: 96),
                                    const SizedBox(height: 12),
                                    Text(
                                      hero.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 0.08,
                        numberOfParticles: 12,
                        maxBlastForce: 18,
                        minBlastForce: 6,
                        gravity: 0.12,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 4),
                            const Text(
                              '¡Bienvenido!',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Crea, comparte y juega donde estés.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AccountTypePage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Continuar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                '¿Ya tienes cuenta? Inicia sesión',
                                style: TextStyle(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Privacidad',
                                  style: TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Términos',
                                  style: TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _BackendSwitcher(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackendSwitcher extends StatelessWidget {
  const _BackendSwitcher();

  Future<void> _switch(BuildContext context, BackendType type, String domain) async {
    await ApiConfigManager.setConfig(type, domain, persist: true);
    if (context.mounted) {
      MyApp.restartApp(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conectado a ${type == BackendType.backcomun ? "BackComun (Prod)" : "QuizzyBackend (Dev)"}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine current active backend to highlight style
    final current = ApiConfigManager.current.backendType;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _btn(context, 
              label: 'BackComun', 
              isActive: current == BackendType.backcomun,
              onTap: () => _switch(context, BackendType.backcomun, 'backcomun-mzvy.onrender.com')),
          const SizedBox(width: 8),
          _btn(context, 
              label: 'Quizzy', 
              isActive: current == BackendType.quizzyBackend, 
              onTap: () => _switch(context, BackendType.quizzyBackend, 'quizzy-backend-1-zpvc.onrender.com')),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, {required String label, required bool isActive, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? Colors.white : Colors.grey,
        backgroundColor: isActive ? AppColor.primary : Colors.transparent,
        side: BorderSide(color: isActive ? AppColor.primary : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _HeroItem {
  final IconData icon;
  final String title;
  const _HeroItem({required this.icon, required this.title});
}
