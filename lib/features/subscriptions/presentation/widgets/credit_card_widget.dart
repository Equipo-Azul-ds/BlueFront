import 'package:flutter/material.dart';

class CreditCardWidget extends StatelessWidget {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;

  const CreditCardWidget({
    super.key,
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Gradiente con tonos más claros para que resalte sobre el fondo azul oscuro
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.contactless, color: Colors.white, size: 32),
              Text(
                'VISA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          Text(
            cardNumber.isEmpty ? '**** **** **** 4242' : cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TITULAR',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      cardHolderName.isEmpty
                          ? 'USUARIO TRIVVY'
                          : cardHolderName.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRA',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    expiryDate.isEmpty ? '12/28' : expiryDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
