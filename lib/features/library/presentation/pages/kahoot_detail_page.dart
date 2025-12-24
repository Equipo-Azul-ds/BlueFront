import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/get_kahoot_detail_use_case.dart';
import '../../domain/entities/kahoot_model.dart';
import '../../domain/entities/kahoot_progress_model.dart';
import '../providers/library_provider.dart';

class KahootDetailPage extends StatelessWidget {
  const KahootDetailPage({super.key});

  // Lógica para cambiar el estado de favorito
  void _toggleFavorite(
    BuildContext context,
    String kahootId,
    bool currentStatus,
  ) async {
    await context.read<LibraryProvider>().toggleFavoriteStatus(
      kahootId: kahootId,
      currentStatus: currentStatus,
    );
  }

  // Simula el fin del juego y actualiza el progreso al 100%
  void _simulateGameCompletion(BuildContext context, String kahootId) async {
    // Llamamos al método del Provider, que ejecuta el Use Case y recarga las listas
    await context.read<LibraryProvider>().updateKahootProgress(
      kahootId: kahootId,
      newPercentage: 100,
      isCompleted: true,
    );
  }

  // Widget para mostrar el estado y progreso
  Widget _buildStatusIndicator(
    BuildContext context,
    Kahoot kahoot,
    KahootProgress? progress,
    String currentUserId, // Recibimos el ID del provider para comparar
  ) {
    // 1. Caso Borrador
    if (kahoot.authorId == currentUserId && kahoot.status == 'Draft') {
      return const Chip(
        label: Text('Borrador'),
        backgroundColor: Colors.grey,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    // 2. Caso En Progreso / Completado
    final percentage = progress?.progressPercentage ?? 0;

    if (percentage > 0 && percentage < 100) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip(
            label: Text('En Progreso'),
            backgroundColor: Colors.orange,
            labelStyle: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            color: Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${percentage.toInt()}% completado',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    if (percentage == 100) {
      return const Chip(
        label: Text('Completado'),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final String kahootId =
        ModalRoute.of(context)!.settings.arguments as String;
    final getKahootDetail = context.read<GetKahootDetailUseCase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Kahoot')),
      body: FutureBuilder<Kahoot>(
        future: getKahootDetail.execute(kahootId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Error al cargar detalles: ${snapshot.error ?? 'No hay datos'}',
              ),
            );
          }

          final Kahoot kahoot = snapshot.data!;

          // Usamos Consumer para acceder al LibraryProvider y escuchar cambios.
          return Consumer<LibraryProvider>(
            builder: (context, manager, child) {
              // Cargamos el progreso específico y reactivo de este Kahoot
              return FutureBuilder<KahootProgress?>(
                // Llama al método del Provider para obtener el progreso individual
                future: manager.getKahootProgress(kahootId),
                builder: (context, progressSnapshot) {
                  // Obtenemos el estado de favorito y progreso
                  final isFavorite = progressSnapshot.data?.isFavorite ?? false;
                  final progress = progressSnapshot.data;
                  final isCurrentlyLoading =
                      progressSnapshot.connectionState ==
                      ConnectionState.waiting;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                kahoot.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.star : Icons.star_border,
                                color: isFavorite ? Colors.amber : Colors.grey,
                                size: 30,
                              ),
                              // Deshabilitar si aún está cargando el progreso
                              onPressed: isCurrentlyLoading
                                  ? null
                                  : () => _toggleFavorite(
                                      context,
                                      kahootId,
                                      isFavorite,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        Text(
                          'Creado por: ${kahoot.authorId}',
                          style: Theme.of(context).textTheme.titleSmall!
                              .copyWith(color: Colors.grey[600]),
                        ),
                        const Divider(height: 16),

                        // === INDICADOR DE ESTADO ===
                        _buildStatusIndicator(
                          context,
                          kahoot,
                          progress,
                          manager.userId,
                        ),
                        const Divider(height: 16),

                        // === BOTÓN SIMULACIÓN DE FINALIZACIÓN ===
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                isCurrentlyLoading ||
                                    (progress?.progressPercentage ?? 0) == 100
                                ? null
                                : () => _simulateGameCompletion(
                                    context,
                                    kahootId,
                                  ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              'Simular Finalización (100%)',
                              style: const TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // === BOTÓN JUGAR ===
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {}, // Lógica real de juego iría aquí
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              (progress?.progressPercentage ?? 0) > 0 &&
                                      (progress?.progressPercentage ?? 0) < 100
                                  ? 'Continuar jugando'
                                  : 'Jugar',
                              style: const TextStyle(fontSize: 18),
                            ),
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
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(kahoot.description),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
