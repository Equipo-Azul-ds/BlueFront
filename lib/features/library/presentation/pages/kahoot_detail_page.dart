import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/get_kahoot_detail_use_case.dart';
import '../../domain/entities/kahoot_model.dart';
import '../providers/library_provider.dart';
import '../../../user/presentation/blocs/auth_bloc.dart';

class KahootDetailPage extends StatelessWidget {
  const KahootDetailPage({super.key});

  void _toggleFavorite(
    BuildContext context,
    String kahootId,
    bool currentStatus,
    String userId,
  ) async {
    final manager = context.read<LibraryProvider>();
    await manager.toggleFavoriteStatus(
      kahootId: kahootId,
      currentStatus: currentStatus,
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String kahootId =
        ModalRoute.of(context)!.settings.arguments as String;
    final getKahootDetail = context.read<GetKahootDetailUseCase>();

    // btenemos el userId real de la Auth
    final authBloc = context.watch<AuthBloc>();
    final currentUserId = authBloc.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Kahoot')),
      body: FutureBuilder<Kahoot>(
        future: getKahootDetail.execute(kahootId, userId: currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar detalles'));
          }

          final kahoot = snapshot.data!;

          return Consumer<LibraryProvider>(
            builder: (context, manager, child) {
              // Verificamos si es favorito buscando en la lista cargada en el provider
              final isFavorite = manager.favoriteKahoots.any(
                (k) => k.id == kahoot.id,
              );

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
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.amber : Colors.grey,
                            size: 30,
                          ),
                          onPressed: () => _toggleFavorite(
                            context,
                            kahootId,
                            isFavorite,
                            currentUserId,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(kahoot.description),
                    const Divider(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          /* Lógica de juego */
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Jugar ahora'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
