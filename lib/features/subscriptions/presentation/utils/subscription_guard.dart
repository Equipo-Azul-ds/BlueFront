import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/subscription_provider.dart';
import '../screens/plans_screen.dart';

class SubscriptionGuard {
  /// 1. Verificador de Funciones Exclusivas (Ej: Tipos de preguntas advanced)
  static bool checkPremium(
    BuildContext context, {
    required String featureName,
  }) {
    final provider = context.read<SubscriptionProvider>();

    if (!provider.isPremium) {
      _showPaywallDialog(
        context: context,
        title: 'Función Premium',
        message:
            'La función "$featureName" solo está disponible para usuarios Premium.',
      );
      return false;
    }
    return true;
  }

  /// 2. Verificador de Límites de Cantidad (Ej: Máximo 5 Kahoots)
  /// [currentCount] es el número actual de elementos que tiene el usuario.
  /// [maxFree] es el límite permitido para el plan gratuito.
  static bool checkLimit(
    BuildContext context, {
    required int currentCount,
    required int maxFree,
    required String itemName,
  }) {
    final provider = context.read<SubscriptionProvider>();

    // Si es premium, no hay límites.
    if (provider.isPremium) return true;

    // Si es free y superó el límite:
    if (currentCount >= maxFree) {
      _showPaywallDialog(
        context: context,
        title: 'Límite alcanzado',
        message:
            'Has alcanzado el límite de $maxFree $itemName en tu plan gratuito. ¡Pásate a Premium para crear sin límites!',
      );
      return false;
    }

    return true;
  }

  /// Diálogo centralizado
  static void _showPaywallDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 50, color: Colors.blue),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Más tarde',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlansScreen()),
              );
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }
}
