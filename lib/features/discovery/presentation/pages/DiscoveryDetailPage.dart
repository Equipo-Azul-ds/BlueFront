import 'package:flutter/material.dart';
import '../../domain/entities/kahoot.dart';

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
                onPressed: () => _hostGame(context, kahoot),
                icon: const Icon(Icons.people, color: Colors.white),
                label: const Text('HOST A GAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _playGame(context, kahoot),
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('JUGAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
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

  void _hostGame(BuildContext context, Kahoot kahoot) {
    print("Hosteando partida para el ID: ${kahoot.id}");
    // Aquí navegarías a la lógica de crear sala/lobby
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Iniciando Lobby para: ${kahoot.title}')),
    );
  }

  void _playGame(BuildContext context, Kahoot kahoot) {
    print("Iniciando juego solo para el ID: ${kahoot.id}");
    // Aquí navegarías a la lógica de juego individual
  }
}