import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../provider/subscription_provider.dart';
import '../widgets/plan_card.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final Color trivvyBlue = const Color(0xFF0D47A1);

  Future<String> _getToken(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    return await authBloc.storage.read('token') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final currentPlanId = subProvider.subscription?.planId ?? 'plan_free';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes y Membresías'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          subProvider.status == SubscriptionStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Mejora tu experiencia',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PLAN GRATUITO
                      PlanCard(
                        title: 'Plan Free',
                        price: 'Gratis',
                        isPremium: false,
                        isCurrentPlan:
                            currentPlanId.toLowerCase().contains('free') ||
                            currentPlanId == 'plan_free',
                        features: const ['Acceso Básico'],
                        onSelected: () => _handlePlanSelection(
                          context,
                          'plan_free',
                          currentPlanId,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // PLAN PREMIUM
                      PlanCard(
                        title: 'Plan Premium',
                        price: '\$9.99/mes',
                        isPremium: true,
                        isCurrentPlan: currentPlanId.toLowerCase().contains(
                          'premium',
                        ),
                        features: const ['Acceso Premium'],
                        onSelected: () => _handlePlanSelection(
                          context,
                          'plan_premium',
                          currentPlanId,
                        ),
                      ),

                      if (subProvider.status == SubscriptionStatus.error)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            '${subProvider.errorMessage}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  void _handlePlanSelection(
    BuildContext context,
    String selectedPlanId,
    String currentPlanId,
  ) async {
    if (selectedPlanId == currentPlanId) return;

    final token = await _getToken(context);

    if (selectedPlanId == 'plan_free') {
      _showDowngradeDialog(context, token);
    } else {
      try {
        await context.read<SubscriptionProvider>().purchasePlan(
          token,
          selectedPlanId,
        );

        if (context.mounted) {
          _showCelebrationOverlay(context);
        }
      } catch (e) {
        // Error manejado por el provider
      }
    }
  }

  void _showCelebrationOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: trivvyBlue.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return FadeTransition(
          opacity: anim1,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                ...List.generate(40, (i) => _ConfettiParticle(index: i)),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stars_rounded,
                          size: 80,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "¡TRIVVY PREMIUM!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        child: Text(
                          "Tu suscripción se ha activado correctamente. Disfruta de todos los beneficios.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: trivvyBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: const Text(
                          "LISTO PARA JUGAR",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDowngradeDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cambio'),
        content: const Text('¿Estás seguro de volver al Plan Gratis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context
                  .read<SubscriptionProvider>()
                  .cancelCurrentSubscription(token);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                // Redirigir al perfil tras cancelar también
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle extends StatelessWidget {
  final int index;
  const _ConfettiParticle({required this.index});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index);
    final colors = [
      Colors.amber,
      Colors.white,
      Colors.blue.shade300,
      Colors.orangeAccent,
    ];
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 1500 + random.nextInt(2000)),
      builder: (context, double value, child) {
        return Positioned(
          top: value * MediaQuery.of(context).size.height,
          left: (random.nextDouble() * MediaQuery.of(context).size.width),
          child: Opacity(
            opacity: 1 - value,
            child: Icon(
              Icons.stop,
              color: colors[random.nextInt(colors.length)],
              size: random.nextDouble() * 10 + 5,
            ),
          ),
        );
      },
    );
  }
}
