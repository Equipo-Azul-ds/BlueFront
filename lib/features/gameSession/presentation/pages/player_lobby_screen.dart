import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';

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
    final quizTitle = sessionController.quizTitle;
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
                          if (quizTitle != null && quizTitle.isNotEmpty) ...[
                            Text(
                              quizTitle,
                              style: const TextStyle(
                                color: AppColor.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Text(
                            'Código del juego',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedPinDisplay(
                            pin: pinCode,
                            spacing: 4,
                            style: const TextStyle(
                              color: AppColor.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _PulsingWaitingIndicator(),
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
                          final width = constraints.maxWidth;
                          final crossAxisCount = width < 520
                              ? 2
                              : (width < 900 ? 3 : 4);
                          final aspectRatio = crossAxisCount == 2 ? 1.15 : 0.95;
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
                            itemBuilder: (context, index) {
                              final player = players[index];
                              final isCurrentUser = player.nickname == nickname;
                              return StaggeredFadeSlide(
                                index: index,
                                child: _LobbyPlayerCard(
                                  player: player,
                                  isCurrentUser: isCurrentUser,
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

/// Tarjeta de jugador en el lobby del jugador, alineada con el lobby del host.
class _LobbyPlayerCard extends StatefulWidget {
  const _LobbyPlayerCard({required this.player, required this.isCurrentUser});

  final SessionPlayer player;
  final bool isCurrentUser;

  @override
  State<_LobbyPlayerCard> createState() => _LobbyPlayerCardState();
}

class _LobbyPlayerCardState extends State<_LobbyPlayerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.player.nickname;
    final isDisconnected = widget.player.isDisconnected;
    final isCurrentUser = widget.isCurrentUser;
    final Color baseColor = isDisconnected
        ? Colors.white.withValues(alpha: 0.05)
        : (isCurrentUser
            ? AppColor.accent.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.12));
    final Color borderColor = isDisconnected
        ? Colors.white38
        : (isCurrentUser
            ? Colors.white
            : Colors.white.withValues(alpha: 0.3));

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: isDisconnected
                    ? Colors.white24
                    : (isCurrentUser
                        ? Colors.white
                        : AppColor.accent.withValues(alpha: 0.6)),
                radius: 24,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isCurrentUser ? AppColor.accent : Colors.white,
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
                  color: isDisconnected
                      ? Colors.white54
                      : (isCurrentUser ? Colors.white : Colors.white),
                  fontWeight: isDisconnected
                      ? FontWeight.w500
                      : (isCurrentUser ? FontWeight.w900 : FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de espera con animación pulsante.
class _PulsingWaitingIndicator extends StatefulWidget {
  const _PulsingWaitingIndicator();

  @override
  State<_PulsingWaitingIndicator> createState() => _PulsingWaitingIndicatorState();
}

class _PulsingWaitingIndicatorState extends State<_PulsingWaitingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: const Icon(
            Icons.watch_later_outlined,
            color: AppColor.primary,
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'El anfitrión prepara la primera pregunta',
            style: TextStyle(color: AppColor.primary),
          ),
        ),
      ],
    );
  }
}
