import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/get_kahoot_detail_use_case.dart';
import '../../domain/entities/kahoot_model.dart';
import '../providers/library_provider.dart';
import '../../../user/presentation/blocs/auth_bloc.dart';
import 'package:Trivvy/core/constants/colors.dart';

import 'package:Trivvy/features/challenge/infrastructure/storage/single_player_attempt_tracker.dart';
import 'package:Trivvy/features/challenge/application/use_cases/single_player_usecases.dart';
import 'package:Trivvy/features/challenge/presentation/pages/single_player_challenge.dart';
import 'package:Trivvy/features/gameSession/presentation/pages/host_lobby.dart';
import 'package:Trivvy/features/challenge/domain/entities/single_player_game.dart';
import 'package:Trivvy/features/challenge/application/dtos/single_player_dtos.dart';

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

  Future<void> _hostGame(BuildContext context, Kahoot kahoot) async {
    final kahootId = (kahoot.id ?? '').trim();
    if (kahootId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este kahoot no tiene un ID válido; sincronízalo antes de hostear.')),
      );
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HostLobbyScreen(kahootId: kahootId),
      ),
    );
  }

  Future<void> _playGame(BuildContext context, Kahoot kahoot) async {
    final kahootId = (kahoot.id ?? '').trim();
    if (kahootId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este kahoot no tiene un ID válido; sincronízalo antes de jugar.')),
      );
      return;
    }

    try {
      final tracker = context.read<SinglePlayerAttemptTracker>();
      final attemptStateUseCase = context.read<GetAttemptStateUseCase>();
      final authBloc = context.read<AuthBloc>();
      final userId = authBloc.currentUser?.id ?? '';

      final storedAttemptId = await tracker.readAttemptId(kahootId, userId);
      SinglePlayerGame? resumeGame;
      SlideDTO? resumeSlide;

      if (storedAttemptId != null) {
        try {
          final attemptState = await attemptStateUseCase.execute(storedAttemptId);
          resumeGame = attemptState.game;
          if (resumeGame == null || resumeGame.gameProgress.state == GameProgressStatus.COMPLETED) {
            await tracker.clearAttempt(kahootId, userId);
            resumeGame = null;
            resumeSlide = null;
          } else {
            resumeSlide = attemptState.nextSlide;
          }
        } catch (e) {
          debugPrint('[discovery] Failed to resume attempt for kahoot=$kahootId -> $e');
          await tracker.clearAttempt(kahootId, userId);
        }
      }

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SinglePlayerChallengeScreen(
            quizId: kahootId,
            initialGame: resumeGame,
            initialSlide: resumeSlide,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[discovery] Error starting single player: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error iniciando juego: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String kahootId =
        ModalRoute.of(context)!.settings.arguments as String;
    final getKahootDetail = context.read<GetKahootDetailUseCase>();

    // btenemos el userId real de la Auth
    final authBloc = context.watch<AuthBloc>();
    final currentUserId = authBloc.currentUser?.id ?? '';

    return FutureBuilder<Kahoot>(
      future: getKahootDetail.execute(kahootId, userId: currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(title: const Text('Detalle del Kahoot')), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(appBar: AppBar(title: const Text('Detalle del Kahoot')), body: const Center(child: Text('Error al cargar detalles')));
        }

        final kahoot = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Detalle del Kahoot')),
          body: Consumer<LibraryProvider>(
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
                    const SizedBox(height: 120), // leave room for bottom sheet
                  ],
                ),
              );
            },
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async => await _hostGame(context, kahoot),
                    icon: const Icon(Icons.people, color: Colors.white),
                    label: const Text('HOST A GAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async => await _playGame(context, kahoot),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('JUGAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secundary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
