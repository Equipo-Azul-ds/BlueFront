import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/subscription_provider.dart';

class PlanBadge extends StatelessWidget {
  const PlanBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado premium del provider
    final isPremium = context.watch<SubscriptionProvider>().isPremium;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Dorado para Premium, Gris azulado para Free
        color: isPremium ? const Color(0xFFFFD700) : Colors.blueGrey.shade300,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.stars : Icons.person_outline,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isPremium ? 'PREMIUM' : 'FREE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
