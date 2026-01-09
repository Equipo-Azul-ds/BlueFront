import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';
import '../provider/subscription_provider.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario del AuthBloc
    final auth = context.watch<AuthBloc>();
    final userId = auth.currentUser?.id ?? '';

    final provider = context.watch<SubscriptionProvider>();
    final subscription = provider.subscription;
    final Color trivvyBlue = const Color(0xFF0D47A1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Suscripción'),
        backgroundColor: trivvyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: provider.status == SubscriptionStatus.loading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Feedback de carga
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // CARD PREMIUM (Solo se muestra si hay suscripción)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.amber.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAN PREMIUM ACTIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Acceso Ilimitado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subscription?.expiresAt != null) ...[
                          const Divider(color: Colors.white30, height: 32),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Renueva el: ${DateFormat('dd MMM, yyyy').format(subscription!.expiresAt!)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: Icon(Icons.layers_outlined, color: trivvyBlue),
                      title: const Text(
                        "Ver todos los planes",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        "Explora otras opciones de suscripción",
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () =>
                          Navigator.pushNamed(context, '/subscriptions'),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón de cancelar pasando el userId
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200, width: 1.5),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () =>
                        _showCancelDialog(context, provider, userId),
                    child: const Text(
                      "CANCELAR SUSCRIPCIÓN",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  if (provider.status == SubscriptionStatus.error)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        provider.errorMessage ?? '',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    SubscriptionProvider provider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Cancelar suscripción?"),
        content: const Text("Tu plan pasará a ser Gratuito inmediatamente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "MANTENER PREMIUM",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              // 3. LLAMADA AL PROVIDER CON EL USERID REAL
              await provider.cancelCurrentSubscription(userId);

              if (context.mounted &&
                  provider.status == SubscriptionStatus.success) {
                Navigator.of(
                  context,
                ).pop(); // Salir de la gestión tras cancelar
              }
            },
            child: const Text(
              "SÍ, CANCELAR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
