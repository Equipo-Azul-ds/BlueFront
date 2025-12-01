// lib/features/library/presentation/pages/kahoot_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/get_kahoot_detail_use_case.dart';
import '../../domain/entities/kahoot_model.dart';

class KahootDetailPage extends StatelessWidget {
  const KahootDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String kahootId =
        ModalRoute.of(context)!.settings.arguments as String;

    final GetKahootDetailUseCase getKahootDetail = context
        .read<GetKahootDetailUseCase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Kahoot')),
      body: FutureBuilder<Kahoot>(
        future: getKahootDetail.execute(kahootId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Kahoot no encontrado.'));
          }

          final Kahoot kahoot = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === TITULO ===
                Text(
                  kahoot.title,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // === AUTOR ===
                Text(
                  'Creado por: ${kahoot.authorId}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(color: Colors.grey[600]),
                ),
                const Divider(height: 32),

                // === BOTÓN JUGAR (ACCIÓN PRINCIPAL) ===
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Iniciando juego...')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Jugar', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // === DESCRIPCIÓN ===
                Text(
                  'Descripción',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(kahoot.description),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
