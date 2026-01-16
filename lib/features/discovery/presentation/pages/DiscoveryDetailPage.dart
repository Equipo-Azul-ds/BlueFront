import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../domain/entities/kahoot.dart';
import 'package:Trivvy/features/challenge/infrastructure/storage/single_player_attempt_tracker.dart';
import 'package:Trivvy/features/challenge/application/use_cases/single_player_usecases.dart';
import 'package:Trivvy/features/challenge/presentation/pages/single_player_challenge.dart';
import 'package:Trivvy/features/gameSession/presentation/pages/host_lobby.dart';
import 'package:Trivvy/features/challenge/domain/entities/single_player_game.dart';
import 'package:Trivvy/features/challenge/application/dtos/single_player_dtos.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';

class DiscoveryDetailPage extends StatelessWidget {
  const DiscoveryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Kahoot kahoot = ModalRoute.of(context)!.settings.arguments as Kahoot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Kahoot'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(color: Colors.grey.shade900),
              child: kahoot.kahootImage != null && kahoot.kahootImage!.isNotEmpty
                  ? Image.network(
                kahoot.kahootImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.white24),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              )
                  : const Center(
                child: Icon(Icons.image, size: 80, color: Colors.white24),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kahoot.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text('Por: ${kahoot.author}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
                  const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(kahoot.description ?? 'Sin descripción.', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 100), // Espacio para no tapar con los botones
                ],
              ),
            ),
          ],
        ),
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
          print('[discovery] Failed to resume attempt for kahoot=$kahootId -> $e');
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
      print('[discovery] Error starting single player: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error iniciando juego: $e')));
    }
  }
}