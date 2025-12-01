import 'package:flutter/material.dart';
import 'host_game.dart';

const Color kPurple = Color(0xFF46178F);

class HostLobbyScreen extends StatelessWidget {
  const HostLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurple,
      body: Stack(
        children: [
          // Background Animation effect placeholder
          Column(
            children: [
              const SizedBox(height: 60),
              // PIN Banner
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4)),
                  child: Column(
                    children: [
                      const Text("Game PIN:",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                      const Text("572 5069",
                          style: TextStyle(
                              color: kPurple,
                              fontSize: 40,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Player Grid (Mock)
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildLobbyPlayer("Wawa"),
                  _buildLobbyPlayer("Test"),
                  _buildLobbyPlayer("CoolGuy"),
                ],
              ),
              const Spacer(),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HostGameScreen()));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLobbyPlayer(String name) {
    return Column(
      children: [
        const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 25,
            child: Icon(Icons.emoji_emotions, color: kPurple)),
        const SizedBox(height: 5),
        Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}