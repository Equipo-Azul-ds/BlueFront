import 'package:flutter/material.dart';
import '/features/challenge/presentation/pages/single_player_lobby.dart'; // Asegurate de tener esta pantalla creada
import 'fake_quiz_data_temporary.dart';

class JoinGameScreen extends StatefulWidget {
  // Se removera despues al elaborar las rutas
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => JoinGameScreenState();
}

class JoinGameScreenState extends State<JoinGameScreen> {
  
  void onEnterPinPressed() {
    // Logica de presionar PIN - por ahora va a pantallas de challenge
    // No deberia de hacer esto pero es para propositos de demostracion hasta que la pantalla de liberia o discovery existan
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
  }

  void onScanQrPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SinglePlayerLobbyScreen()),
    );  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de Fondo
      backgroundColor: const Color(0xFF121212), 
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Boton Cerrar
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () {
                      // Aqui la logica para volver al dashboard
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
                  
                  // Boton de Ayuda
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.question_mark, 
                      color: Colors.black, 
                      size: 20
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido Principal
            const Spacer(flex: 2), 

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
                autofocus: true, // Abre el teclado automaticamente
              ),
            ),

            const Spacer(flex: 3),

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
                      icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
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
    );
  }
}