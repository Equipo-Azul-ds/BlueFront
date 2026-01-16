import 'package:flutter/material.dart';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import '../../../../core/constants/colors.dart'; // Ajusta a tus colores

class AiQuizGeneratorPage extends StatefulWidget {
  const AiQuizGeneratorPage({super.key});

  @override
  State<AiQuizGeneratorPage> createState() => _AiQuizGeneratorPageState();
}

class _AiQuizGeneratorPageState extends State<AiQuizGeneratorPage> {
  final SmartReply _smartReply = SmartReply();
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _smartReply.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateIdeas(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    // 1. Añadimos contexto para "engañar" al modelo de chat y que genere ideas
    _smartReply.addMessageToConversationFromRemoteUser(
      'Dame temas creativos para un examen o quiz sobre:',
      DateTime.now().millisecondsSinceEpoch,
      'system',
    );

    // 2. Añadimos lo que el usuario escribió
    _smartReply.addMessageToConversationFromLocalUser(
      text,
      DateTime.now().millisecondsSinceEpoch,
    );

    // 3. Obtenemos respuesta del modelo local (ML Kit)
    final result = await _smartReply.suggestReplies();

    setState(() {
      _suggestions = result.suggestions;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Ideas IA'),
        backgroundColor: AppColor.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Sobre qué quieres crear un Quiz?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ej: Historia, Matemáticas, Películas...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                  onPressed: () => _generateIdeas(_controller.text),
                ),
              ),
              onSubmitted: _generateIdeas,
            ),
            const SizedBox(height: 25),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_suggestions.isNotEmpty) ...[
              const Text('Sugerencias de la IA:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestions.map((idea) => ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline, size: 16),
                  label: Text(idea),
                  onPressed: () {
                    _controller.text = idea;
                  },
                  backgroundColor: Colors.purple.shade50,
                )).toList(),
              ),
            ],
            const Spacer(),

          ],
        ),
      ),
    );
  }
}