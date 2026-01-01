import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../widgets/credit_card_widget.dart';
import '../provider/subscription_provider.dart';

class PaymentFormScreen extends StatefulWidget {
  final String planId;
  const PaymentFormScreen({super.key, required this.planId});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  bool _isProcessing = false;
  final Color trivvyBlue = const Color(0xFF0D47A1);

  // Controladores para actualizar la tarjeta en tiempo real
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Escuchamos los cambios para que la UI se refresque al escribir
    _numberController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _handlePayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    final provider = context.read<SubscriptionProvider>();
    await provider.purchasePlan(widget.planId);

    setState(() => _isProcessing = false);

    if (provider.isPremium) {
      _showCelebrationOverlay();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error en la transacción'),
        ),
      );
    }
  }

  void _showCelebrationOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: trivvyBlue.withValues(alpha: 0.95),
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
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        child: Text(
                          "Tu suscripción se ha activado correctamente.",
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
                        onPressed: () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirmar Suscripción'),
        backgroundColor: trivvyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: trivvyBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 35, top: 10),
              child: CreditCardWidget(
                cardNumber: _numberController.text,
                cardHolderName: _nameController.text,
                expiryDate: _expiryController.text,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildField(
                    "Nombre en la tarjeta",
                    Icons.person_outline,
                    _nameController,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    "Número de tarjeta",
                    Icons.credit_card,
                    _numberController,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          "Expiración (MM/AA)",
                          Icons.calendar_month,
                          _expiryController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          "CVV",
                          Icons.lock_outline,
                          _cvvController,
                          isObscure: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: trivvyBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handlePayment,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "PAGAR Y ACTIVAR PREMIUM",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isObscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: trivvyBlue),
        filled: true,
        fillColor: Colors.blue.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
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
