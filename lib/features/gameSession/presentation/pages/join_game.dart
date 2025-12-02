import 'package:flutter/material.dart';
import '/features/challenge/presentation/pages/single_player_challenge.dart';
import 'host_setup.dart';

class JoinGameScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const JoinGameScreen({super.key, this.scrollController});

  @override
  State<JoinGameScreen> createState() => JoinGameScreenState();
}

class JoinGameScreenState extends State<JoinGameScreen> {
  void onEnterPinPressed() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HostSetupScreen()));
  }

  void onScanQrPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SinglePlayerChallengeScreen(
          nickname: 'Player',
          quizId: 'mock_quiz_1',
          totalQuestions: 5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Boton Cerrar: close the modal/page
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),

                    // Titulo
                    const Text(
                      "Unirse a un juego",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 32, height: 32),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.06),

              // Contenido Principal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  // Cursor
                  cursorColor: Colors.white,
                  cursorHeight: 64,
                  cursorWidth: 3,
                  decoration: InputDecoration(
                    hintText: 'PIN',
                    hintStyle: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: false,
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.08),

              // Botones Abajo
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: Row(
                  children: [
                    // Boton "Introduzca PIN"
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onEnterPinPressed,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          overlayColor: const Color(0xFF333333),
                        ),
                        icon: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        label: const Text(
                          "Introduzca PIN",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Boton "Escanear codigo QR"
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onScanQrPressed,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          foregroundColor: Colors.white,
                          overlayColor: const Color(0xFF333333),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 22),
                        label: const Text(
                          "(Temporal) Prueba de Single Player",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
