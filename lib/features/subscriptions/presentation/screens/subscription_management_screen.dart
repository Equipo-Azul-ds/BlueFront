import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';
import '../provider/subscription_provider.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  Future<String> _getToken(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    return await authBloc.storage.read('token') ?? '';
  }

  @override
  Widget build(BuildContext context) {
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // CARD PREMIUM
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

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200, width: 1.5),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => _showCancelDialog(context, provider),
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

  void _showCancelDialog(BuildContext context, SubscriptionProvider provider) {
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

              // Obtener el token y enviarlo al provider
              final token = await _getToken(context);
              await provider.cancelCurrentSubscription(token);

              if (context.mounted &&
                  provider.status == SubscriptionStatus.success) {
                // Regresar a la pantalla anterior (Perfil) tras éxito
                Navigator.of(context).pop();
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
