import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';

class QuizAIService {
  final _smartReply = SmartReply();

  Future<List<String>> getQuizIdeas(String userText) async {
    // 1. Añadimos el "contexto" de la conversación.
    // Simulamos que el sistema le pregunta al usuario qué quiere hacer.
    _smartReply.addMessageToConversationFromRemoteUser(
      '¿Sobre qué tema te gustaría crear un quiz hoy?',
      DateTime.now().millisecondsSinceEpoch,
      'system_id',
    );

    // 2. Añadimos lo que el usuario escribió
    _smartReply.addMessageToConversationFromLocalUser(
      userText,
      DateTime.now().millisecondsSinceEpoch,
    );

    // 3. Obtenemos las sugerencias generadas por el modelo local
    final response = await _smartReply.suggestReplies();

    // Limpiamos el historial para la próxima consulta
    _smartReply.close();

    return response.suggestions;
  }
}