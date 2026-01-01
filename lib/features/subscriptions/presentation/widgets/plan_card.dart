import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final VoidCallback onSelected;
  final bool isPremium;
  final bool isCurrentPlan;

  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    required this.onSelected,
    this.isPremium = false,
    this.isCurrentPlan = false,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos colores basados en si es el plan actual o si es premium
    final Color primaryColor = isPremium
        ? Colors.amber.shade700
        : Colors.blueGrey;
    final Color? cardBgColor = isCurrentPlan
        ? Colors.grey.shade100
        : Colors.white;

    return Card(
      elevation: isCurrentPlan ? 0 : (isPremium ? 8 : 2),
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentPlan
            ? BorderSide(color: Colors.grey.shade300, width: 1)
            : (isPremium
                  ? BorderSide(color: Colors.amber.shade700, width: 2)
                  : BorderSide.none),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (isCurrentPlan)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PLAN ACTUAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isCurrentPlan ? Colors.grey : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              price,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isCurrentPlan
                    ? Colors.grey
                    : (isPremium ? Colors.amber.shade800 : Colors.blueAccent),
              ),
            ),
            const Divider(height: 30),
            // Lista de características
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: isCurrentPlan
                          ? Colors.grey
                          : (isPremium ? Colors.amber.shade700 : Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: isCurrentPlan ? Colors.grey : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Botón de acción
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : onSelected, // Se deshabilita si es el plan actual
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isCurrentPlan ? 0 : 4,
                ),
                child: Text(
                  isCurrentPlan
                      ? 'Plan Activo'
                      : (isPremium ? 'Subir a Premium' : 'Elegir Plan Free'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
