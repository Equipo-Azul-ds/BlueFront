import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';
import '../provider/subscription_provider.dart';
import '../widgets/plan_card.dart';
import 'payment_form_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario autenticado
    final auth = context.watch<AuthBloc>();
    final userId = auth.currentUser?.id ?? '';

    final subProvider = context.watch<SubscriptionProvider>();
    final currentPlanId = subProvider.subscription?.planId ?? 'plan_free';

    return Scaffold(
      appBar: AppBar(title: const Text('Planes y Membresías')),
      body: subProvider.status == SubscriptionStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Mejora tu experiencia',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // PLAN GRATUITO
                  PlanCard(
                    title: 'Plan Free',
                    price: 'Gratis',
                    isPremium: false,
                    isCurrentPlan: currentPlanId == 'plan_free',
                    features: const ['Hasta 5 quices creados'],
                    onSelected: () => _handlePlanSelection(
                      context,
                      'plan_free',
                      currentPlanId,
                      userId,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // PLAN PREMIUM
                  PlanCard(
                    title: 'Plan Premium',
                    price: '\$9.99/mes',
                    isPremium: true,
                    isCurrentPlan: currentPlanId == 'plan_premium',
                    features: const ['Kahoots ilimitados'],
                    onSelected: () => _handlePlanSelection(
                      context,
                      'plan_premium',
                      currentPlanId,
                      userId,
                    ),
                  ),

                  if (subProvider.status == SubscriptionStatus.error)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Error: ${subProvider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _handlePlanSelection(
    BuildContext context,
    String selectedPlanId,
    String currentPlanId,
    String userId,
  ) {
    if (selectedPlanId == currentPlanId) return;

    if (selectedPlanId == 'plan_free') {
      _showDowngradeDialog(context, userId); // Pasar userId al diálogo
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFormScreen(
            planId: selectedPlanId,
            userId: userId, // Pasar userId al formulario de pago
          ),
        ),
      );
    }
  }

  void _showDowngradeDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar al Plan Gratis'),
        content: const Text(
          '¿Estás seguro? Perderás el acceso a los beneficios Premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Enviamos userId y planId
                await context.read<SubscriptionProvider>().purchasePlan(
                  userId,
                  'plan_free',
                );

                if (!context.mounted) return;
                Navigator.pop(ctx);
                Navigator.of(context).popUntil(
                  (route) => route.isFirst || route.settings.name == '/profile',
                );
              } catch (e) {
                // El error ya lo maneja el provider para mostrarlo en pantalla
                Navigator.pop(ctx);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
