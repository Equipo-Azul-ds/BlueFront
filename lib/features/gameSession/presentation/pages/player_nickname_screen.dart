import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';

import '../controllers/multiplayer_session_controller.dart';
import 'player_lobby_screen.dart';

/// Pantalla para que el jugador ingrese o cambie su apodo después de unirse a una sala.
class PlayerNicknameScreen extends StatefulWidget {
  const PlayerNicknameScreen({
    super.key,
    this.initialNickname,
    this.isFirstTime = false,
  });

  /// Apodo inicial sugerido.
  final String? initialNickname;

  /// Si es verdadero, muestra que es la primera vez; si falso, es una oportunidad de cambio.
  final bool isFirstTime;

  @override
  State<PlayerNicknameScreen> createState() => _PlayerNicknameScreenState();
}

class _PlayerNicknameScreenState extends State<PlayerNicknameScreen> {
  late final TextEditingController _nicknameController;
  bool _isSubmitting = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.initialNickname ?? '',
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// Valida que el apodo cumpla con los requisitos (6-20 caracteres).
  bool _isValidNickname(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < 6) return false;
    if (trimmed.length > 20) return false;
    return true;
  }

  /// Intenta confirmar el apodo y unirse al lobby.
  Future<void> _onConfirmPressed() async {
    final nickname = _nicknameController.text;

    if (!_isValidNickname(nickname)) {
      setState(() {
        _validationError = 'El apodo debe tener entre 6 y 20 caracteres';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    try {
      final controller = context.read<MultiplayerSessionController>();

      // Emitir evento player_join con el nuevo apodo
      await controller.joinLobbyWithNickname(nickname: nickname.trim());

      if (!mounted) return;

      // Navega al lobby
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlayerLobbyScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Error: ${error.toString()}';
        _isSubmitting = false;
      });
    }
  }

  void _onSkipPressed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PlayerLobbyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width > 600;

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
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.isFirstTime
                            ? '¿Cuál es tu apodo?'
                            : 'Cambiar apodo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.isFirstTime
                            ? 'Elige un apodo para identificarte durante el juego'
                            : 'Puedes cambiar tu apodo antes de empezar',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _nicknameController,
                        enabled: !_isSubmitting,
                        maxLength: 20,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onConfirmPressed(),
                        decoration: InputDecoration(
                          hintText: 'Entre 6 y 20 caracteres',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.white70,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          counterStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          errorText: _validationError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onConfirmPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.secundary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Continuar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _onSkipPressed,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Saltarse',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
