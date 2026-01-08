import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../controllers/multiplayer_session_controller.dart';
import 'package:Trivvy/core/widgets/game_ui_kit.dart';
import '../widgets/realtime_error_handler.dart';
import 'host_game.dart';

const _defaultQuizTitle = 'Trivvy!';
const _placeholderPin = '------';

/// Lobby del anfitrión: crea sesión y muestra jugadores conectados.
class HostLobbyScreen extends StatefulWidget {
  const HostLobbyScreen({
    super.key,
    required this.kahootId,
  });

  final String kahootId;

  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  final RealtimeErrorHandler _errorHandler = RealtimeErrorHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHostSession());
  }

  /// Solicita la creación de la sala y maneja errores locales.
  Future<void> _initHostSession() async {
    final controller = context.read<MultiplayerSessionController>();
    try {
      await controller.initializeHostLobby(
        kahootId: widget.kahootId,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('No se pudo crear la sala: $error');
    }
  }

  /// Helper para mostrar mensajes de error/sistema.
  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
    final players = sessionController.lobbyPlayers;
    final isLoading = sessionController.isCreatingSession;
    final quizTitle = sessionController.quizTitle ?? _defaultQuizTitle;
    final pinCode = sessionController.sessionPin ?? _placeholderPin;
    final stateError = sessionController.lastError;

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
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await context
                                .read<MultiplayerSessionController>()
                                .leaveSession();
                            if (!mounted) return;
                            navigator.pop();
                          },
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Lobby del anfitrión',
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
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quizTitle,
                            style: const TextStyle(
                              color: AppColor.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Código del juego',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Text(
                              pinCode,
                              style: const TextStyle(
                                color: AppColor.primary,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              Icon(
                                Icons.share_arrival_time,
                                color: AppColor.primary,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Comparte el PIN para que se unan los jugadores',
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
                          '${players.length} en sala',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          // Estados: error recuperable, vacío o lista de jugadores.
                          if (stateError != null && players.isEmpty) {
                            return _ErrorState(
                              onRetry: _initHostSession,
                              message: stateError,
                            );
                          }
                          if (players.isEmpty) {
                            return const _EmptyLobbyPlaceholder();
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width < 520
                                  ? 2
                                  : (width < 900 ? 3 : 4);
                              final aspectRatio = crossAxisCount == 2
                                  ? 1.15
                                  : 0.95;
                              return GridView.builder(
                                padding: const EdgeInsets.only(top: 4),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: aspectRatio,
                                    ),
                                itemCount: players.length,
                                    itemBuilder: (_, index) =>
                                      _LobbyPlayerCard(player: players[index]),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Iniciar partida',
                      icon: Icons.play_arrow_rounded,
                      onPressed: sessionController.canHostStartGame
                          ? () {
                              sessionController.emitHostStartGame();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const HostGameScreen(),
                                ),
                              );
                            }
                          : null,
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

/// Tarjeta de jugador conectado al lobby del host.
class _LobbyPlayerCard extends StatelessWidget {
  final SessionPlayer player;

  const _LobbyPlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final name = player.nickname;
    final isDisconnected = player.isDisconnected;
    return Container(
      decoration: BoxDecoration(
        color: isDisconnected
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisconnected
              ? Colors.white38
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: isDisconnected
                ? Colors.white24
                : AppColor.accent.withValues(alpha: 0.6),
            radius: 24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isDisconnected ? '$name (desconectado)' : name,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDisconnected ? Colors.white54 : Colors.white,
              fontWeight: isDisconnected ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantalla de error recuperable en lobby.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const _ErrorState({required this.onRetry, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Placeholder cuando aún no hay jugadores conectados.
class _EmptyLobbyPlaceholder extends StatelessWidget {
  const _EmptyLobbyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.group_outlined, color: Colors.white70, size: 48),
          SizedBox(height: 12),
          Text(
            'Aún no hay jugadores conectados. Comparte el PIN o QR para comenzar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
