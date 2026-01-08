import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../controllers/multiplayer_session_controller.dart';
import 'package:Trivvy/core/widgets/game_ui_kit.dart';
import '../widgets/realtime_error_handler.dart';
import 'player_question_screen.dart';

const _fallbackNickname = 'Jugador';
const _placeholderPin = '------';

/// Lobby de jugador: espera al anfitrión y muestra lista de conectados.
class PlayerLobbyScreen extends StatefulWidget {
  const PlayerLobbyScreen({super.key});

  @override
  State<PlayerLobbyScreen> createState() => _PlayerLobbyScreenState();
}

class _PlayerLobbyScreenState extends State<PlayerLobbyScreen> {
  final RealtimeErrorHandler _errorHandler = RealtimeErrorHandler();

  @override
  Widget build(BuildContext context) {
    final sessionController = context.watch<MultiplayerSessionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _errorHandler.handle(
        context: context,
        controller: sessionController,
        onExit: _exitToHome,
      );
    });

    final resolvedNickname = sessionController.currentNickname?.trim();
    final nickname = (resolvedNickname?.isNotEmpty ?? false)
        ? resolvedNickname!
        : _fallbackNickname;
    final pinCode = sessionController.sessionPin ?? _placeholderPin;
    // Usa el propio jugador como placeholder si el lobby aún no sincroniza.
    final playersSource = sessionController.lobbyPlayers.isEmpty
        ? <SessionPlayer>[SessionPlayer(playerId: 'local', nickname: nickname)]
        : sessionController.lobbyPlayers;
    final players = [...playersSource]
      ..sort((a, b) {
        if (a.nickname == nickname) return -1;
        if (b.nickname == nickname) return 1;
        return a.nickname.compareTo(b.nickname);
      });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.primary, AppColor.secundary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await context
                                .read<MultiplayerSessionController>()
                                .leaveSession();
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sala de espera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Código del juego',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pinCode,
                            style: const TextStyle(
                              color: AppColor.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              Icon(
                                Icons.watch_later_outlined,
                                color: AppColor.primary,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'El anfitrión prepara la primera pregunta',
                                  style: TextStyle(color: AppColor.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jugadores conectados',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${players.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth < 420
                              ? 1
                              : 2;
                          final aspectRatio = crossAxisCount == 1 ? 5.5 : 3.5;
                          return GridView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: aspectRatio,
                                ),
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              final isCurrentUser = player.nickname == nickname;
                              final isDisconnected = player.isDisconnected;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  color: isDisconnected
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : (isCurrentUser
                                          ? AppColor.accent
                                          : Colors.white.withValues(alpha: 0.12)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDisconnected
                                        ? Colors.white38
                                        : (isCurrentUser
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.3)),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isDisconnected
                                          ? Icons.wifi_off_rounded
                                          : (isCurrentUser
                                              ? Icons.sentiment_satisfied_alt
                                              : Icons.smart_toy_outlined),
                                      color: isDisconnected
                                          ? Colors.white54
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        isDisconnected
                                            ? '${player.nickname} (desconectado)'
                                            : player.nickname,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDisconnected
                                              ? Colors.white54
                                              : (isCurrentUser
                                                  ? Colors.white
                                                  : Colors.white70),
                                          fontWeight: isDisconnected
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Estoy listo',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerQuestionScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _exitToHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
