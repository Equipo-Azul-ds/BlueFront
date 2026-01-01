import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/subscription_provider.dart';
import '../widgets/plan_card.dart';
import 'payment_form_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Mejora tu experiencia en Trivvy',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // PLAN GRATUITO
                  PlanCard(
                    title: 'Plan Free',
                    price: 'Gratis',
                    isPremium: false,
                    isCurrentPlan: currentPlanId == 'plan_free',
                    features: const [
                      'Hasta 5 quices creados',
                      'Tipos de pregunta: Quiz y Verdadero/Falso',
                    ],
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
                    isCurrentPlan: currentPlanId == 'plan_premium',
                    features: const [
                      'Kahoots ilimitados',
                      'Acceso a todos los tipos de pregunta',
                      'Personalización de temas visuales',
                    ],
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
  ) {
    if (selectedPlanId == currentPlanId) return;

    if (selectedPlanId == 'plan_free') {
      // Si pasa de Premium a Gratis, se procesa directamente o con confirmación
      _showDowngradeDialog(context);
    } else {
      // Si va a Premium, enviamos al formulario de pago
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFormScreen(planId: selectedPlanId),
        ),
      );
    }
  }

  void _showDowngradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar al Plan Gratis'),
        content: const Text(
          '¿Estás seguro? Perderás el acceso a la creación ilimitada y todos tus beneficios Premium',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Ejecutamos el cambio de plan
              await context.read<SubscriptionProvider>().purchasePlan(
                'plan_free',
              );

              if (!context.mounted) return;

              // Cerramos el diálogo
              Navigator.pop(context);

              // Volvemos a la raíz
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
