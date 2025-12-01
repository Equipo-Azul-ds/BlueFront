import 'package:flutter/material.dart';

const Color purpleDark = Color(0xFF4B0082);
const Color purpleLight = Color(0xFF8A2BE2);

class MultiplayerLeaderboardScreen extends StatelessWidget {
  final String nickname;
  final int finalScore;
  final int totalQuestions;
  final int correctAnswers;

  const MultiplayerLeaderboardScreen({
    super.key,
    required this.nickname,
    required this.finalScore,
    required this.totalQuestions,
    required this.correctAnswers, 
  });

// Prefijos
  String getOrdinal(int n) {
    if (n >= 11 && n <= 13) {
      return 'vo';
    }
    switch (n % 10) {
      case 1: return 'er';
      case 2: return 'do';
      case 3: return 'ro';
      default: return 'to';
    }
  }

  // Mock de un leaderboard
  static List<Map<String, dynamic>> initialMockPlayers = [
    {'name': 'Shima', 'score': 943, 'correct': 2},
    {'name': 'Robyn', 'score': 948, 'correct': 3},
    {'name': 'Mal', 'score': 788, 'correct': 1},
    {'name': 'Nancy', 'score': 1050, 'correct': 3},
    {'name': 'Zane', 'score': 500, 'correct': 1},
  ];

  List<Map<String, dynamic>> get dynamicLeaderboard {
    // Crea el mock de la lista
    final List<Map<String, dynamic>> players = List.from(initialMockPlayers);

    // Añade al jugador
    players.add({
      'name': nickname,
      'score': finalScore,
      'correct': correctAnswers,
    });
    // Ordena por puntaje descendente
    players.sort((a, b) => b['score'].compareTo(a['score']));

    // Asigna ranking
    for (int i = 0; i < players.length; i++) {
      players[i]['rank'] = i + 1;
    }
    return players;
  }

  // Busca al jugador de la lista
  Map<String, dynamic> getUserData(List<Map<String, dynamic>> fullLeaderboard) {
    return fullLeaderboard.firstWhere(
      (p) => p['name'] == nickname && p['score'] == finalScore,
      orElse: () => {'name': nickname, 'score': finalScore, 'rank': fullLeaderboard.length, 'correct': correctAnswers},
    );
  }


  @override
  Widget build(BuildContext context) {
    // 1. Genera el leaderboard completo y dinámico
    final List<Map<String, dynamic>> fullLeaderboard = dynamicLeaderboard;
    
    // 2. Obtiene los datos específicos para el usuario
    final Map<String, dynamic> userData = getUserData(fullLeaderboard);
    final int userRank = userData['rank'];
    
    // 3. Extrae un top 3
    final List<Map<String, dynamic>> topPlayers = fullLeaderboard.take(3).toList();

    // 4. Ordena los widgets por orden de top ranking y guarda el orden
    List<Widget> podiumColumns = [];

    // Indices para cada posicion
    const int firstPlaceIndex = 0;
    const int secondPlaceIndex = 1;
    const int thirdPlaceIndex = 2;
    
    // Verifica el 2do Lugar (índice 1) - VISUALMENTE IZQUIERDA
    if (topPlayers.length > secondPlaceIndex) {
      podiumColumns.add(buildPodiumColumn(context, topPlayers[secondPlaceIndex], heightFactor: 0.8)); 
    }
    
    // Verifica el 1er Lugar (índice 0) - VISUALMENTE CENTRO
    if (topPlayers.length > firstPlaceIndex) {
      podiumColumns.add(buildPodiumColumn(context, topPlayers[firstPlaceIndex], heightFactor: 1.0));
    }
    
    // Verifica el 3er Lugar (index 2) - VISUALEMNTE DERECHA
    if (topPlayers.length > thirdPlaceIndex) {
      podiumColumns.add(buildPodiumColumn(context, topPlayers[thirdPlaceIndex], heightFactor: 0.6));
    }


    return Scaffold(
      body: Container(
        // Probando Gradiente
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [purpleLight, purpleDark],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Trivvy!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Titulo del Quiz
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'Probando',
                        style: TextStyle(
                          color: purpleDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Visualizacion del podium
                    SizedBox(
                      height: 350,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: podiumColumns,
                      ),
                    ),
                    const Spacer(),

                    // Mensaje de ranking y puntaje para el jugador
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: "Estas en ",
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            children: [
                              TextSpan(
                                text: '$userRank${getOrdinal(userRank)} lugar',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              TextSpan(
                                text: ' con $finalScore puntos!',
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Volver a jugar (por ahora lleva a la pantalla de pin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Navegar de regreso a la pantalla de unión o al menú principal
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: purpleDark,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 10,
                        ),
                        child: const Text(
                          'Jugar otra vez',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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

  // Construye los podiums individuales
  Widget buildPodiumColumn(BuildContext context, Map<String, dynamic> player, {required double heightFactor}) {
    final int rank = player['rank'];
    final Color rankColor = rank == 1 ? const Color(0xFFFFCC00) : rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32);
    final IconData rankIcon = rank == 1 ? Icons.looks_one_rounded : rank == 2 ? Icons.looks_two_rounded : Icons.looks_3_rounded;
    final int columnHeight = (300 * heightFactor).round();
    
    // Chequea si el podium que se esta construyendo es el usuario actual y asigna un color distinto si es el caso
    final bool isUser = player['name'] == nickname && player['score'] == finalScore;
    final Color nameTagColor = isUser ? const Color(0xFF40E0D0) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nombre del jugador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: nameTagColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player['name'],
              style: TextStyle(
                color: isUser ? Colors.white : purpleDark,
                fontWeight: rank == 1 ? FontWeight.w900 : FontWeight.bold,
                fontSize: rank == 1 ? 24 : 18,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Barra del podium
          Container(
            width: 100,
            height: columnHeight.toDouble(),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF40E0D0).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono de ranking
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    rankIcon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                
                // Detalles de puntaje y respuestas correctas
                Column(
                  children: [
                    Text(
                      '${player['score']}',
                      style: TextStyle(
                        color: isUser ? const Color(0xFF40E0D0) : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${player['correct']} de $totalQuestions',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}