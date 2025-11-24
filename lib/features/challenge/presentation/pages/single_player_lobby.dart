import 'package:flutter/material.dart';
import '/features/challenge/presentation/pages/single_player_challenge.dart';

const Color purpleDark = Color(0xFF4B0082); 
const Color purpleLight = Color(0xFF8A2BE2);

class SinglePlayerLobbyScreen extends StatefulWidget {
  const SinglePlayerLobbyScreen({super.key});

  @override
  State<SinglePlayerLobbyScreen> createState() => SinglePlayerLobbyScreenState();
}

class SinglePlayerLobbyScreenState extends State<SinglePlayerLobbyScreen> {
  final TextEditingController nicknameController = TextEditingController();
  // Mock de Jugadores
  final List<String> examplePlayers = ['Nancy', 'Robyn', 'Shima', 'Mal'];
  String nickname = '';

  void onStartPressed() {
    if (nickname.trim().isNotEmpty) {
      // Navega a la pantalla del Challenge
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SinglePlayerChallengeScreen(nickname: nickname),
        ),
      );
    } else {
      // Error en el input
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduzca su nickname para empezar el juego.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Probando Gradientes
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [purpleLight,purpleDark],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(59, 166, 0, 243),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -200,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(34, 255, 255, 255),
                  borderRadius: BorderRadius.circular(200),
                ),
              ),
            ),
            
            // Contenido
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Seccion Principal
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        // Header Principal
                        const Text(
                          'Desafio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Informacion del Quiz/Challenge
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: Row(
                            children: [
                              // Placeholder para la foto del Quiz
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey,
                                alignment: Alignment.center,
                                child: const Text('Foto de Quiz', style: TextStyle(color: Colors.black)),
                              ),
                              const SizedBox(width: 15),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Probando', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 18)),
                                    Text('Tiempo del challenge que esta abierto, opcional?', style: TextStyle(color: Color(0xFF40E0D0), fontSize: 12)),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Cantidad de Preguntas', style: TextStyle(color: Color.fromARGB(179, 0, 0, 0), fontSize: 12)),
                                        Text('Creado Por:', style: TextStyle(color: Color.fromARGB(179, 0, 0, 0), fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Titulo Trivvy
                        const Text(
                          'Trivvy!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Mock para mostrar los nicknames de jugadores
                        Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          alignment: WrapAlignment.center,
                          children: examplePlayers.map((name) {
                            return Chip(
                              label: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.white,
                              labelStyle: const TextStyle(color: purpleDark),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Boton de Join
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50.0),
                      child: Column(
                        children: [
                          const Text(
                            'Unirse al juego',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Input de nickname
                              SizedBox(
                                width: 180,
                                child: TextField(
                                  controller: nicknameController,
                                  onChanged: (value) {
                                    setState(() {
                                      nickname = value;
                                    });
                                  },
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    hintText: 'Introduzca un nickname',
                                    fillColor: Colors.white,
                                    filled: true,
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Boton de Empezar
                              ElevatedButton(
                                onPressed: onStartPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF40E0D0), // Aqua color
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                child: const Text(
                                  'Empezar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}