import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/subscription_provider.dart';
import 'plans_screen.dart';
import 'subscription_management_screen.dart';

class SubscriptionGatePage extends StatelessWidget {
  const SubscriptionGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();

    // Si es Premium, mostramos Gestión. Si no, mostramos Planes.
    if (provider.isPremium) {
      return const SubscriptionManagementScreen();
    } else {
      return const PlansScreen();
    }
  }
}
