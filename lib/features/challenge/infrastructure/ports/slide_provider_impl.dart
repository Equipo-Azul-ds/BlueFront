import 'dart:async';
import '../../application/ports/slide_provider.dart';
import '../../application/dtos/single_player_dtos.dart';

/// Implementación en memoria del `SlideProvider` usada por la infraestructura.
///
/// Contiene un banco de preguntas (mock), un mapa con índices de respuesta
/// correcta y mantiene un puntero por intento (`_questionPosition`) que indica
/// la próxima slide a servir. También expone `ensurePointerSynced` para que el
/// servicio que crea/reaunuda intentos pueda sincronizar el puntero.
class SlideProviderImpl implements SlideProvider {
  final Map<String, int> _questionPosition = {};

  // Banco de slides (solo para infra/mock)
  final List<SlideDTO> _mockSlides = [
    SlideDTO(
      slideId: 'q1',
      questionText: 'What is 2 + 2?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: '3'),
        SlideOptionDTO(index: 1, text: '4'),
        SlideOptionDTO(index: 2, text: '5'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q2',
      questionText: 'What is the capital of France?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: 'Paris'),
        SlideOptionDTO(index: 1, text: 'London'),
        SlideOptionDTO(index: 2, text: 'Berlin'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q3',
      questionText: 'Which planet is known as the Red Planet?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: 'Earth'),
        SlideOptionDTO(index: 1, text: 'Mars'),
        SlideOptionDTO(index: 2, text: 'Venus'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q4',
      questionText: 'What is the boiling point of water (°C)?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: '90'),
        SlideOptionDTO(index: 1, text: '100'),
        SlideOptionDTO(index: 2, text: '110'),
      ],
      mediaUrl: null,
    ),
    SlideDTO(
      slideId: 'q5',
      questionText: 'Which language is primary for Flutter development?',
      questionType: 'quiz',
      timeLimitSeconds: 20,
      options: [
        SlideOptionDTO(index: 0, text: 'Java'),
        SlideOptionDTO(index: 1, text: 'Dart'),
        SlideOptionDTO(index: 2, text: 'Kotlin'),
      ],
      mediaUrl: null,
    ),
  ];

  // Mapa de respuestas correctas (infra/mock)
  final Map<String, int> _correctAnswers = {
    'q1': 1,
    'q2': 0,
    'q3': 1,
    'q4': 1,
    'q5': 1,
  };

  @override
  Future<SlideDTO?> getNextSlideDto(String attemptId) async {
    // getNextSlideDto: devuelve la siguiente slide para `attemptId` y
    // avanza el puntero interno. Simula una pequeña latencia para emular
    // una llamada de red/IO.
    // IMPORTANTE: este método avanza el puntero; no usarlo si se desea
    // solamente obtener metadata sin afectar el flujo (usar `peekSlideDto`).

    final idx = _questionPosition[attemptId] ?? 0;
    if (idx >= _mockSlides.length) return null;

    final slide = _mockSlides[idx];
    _questionPosition[attemptId] = idx + 1;
    return slide;
  }

  @override
  Future<int?> getCorrectAnswerIndex(
    String attemptId,
    String questionId,
  ) async {
    // getCorrectAnswerIndex: devuelve el índice correcto para `questionId`.
    // Si la pregunta no existe en el banco mock, devuelve null.
    return _correctAnswers[questionId];
  }

  @override
  Future<SlideDTO?> peekSlideDto(String attemptId, int index) async {
    // peekSlideDto: obtiene la slide en `index` sin modificar el puntero
    // interno. Útil para que la capa de dominio/infra obtenga metadatos
    // de una slide concreta cuando no queremos avanzar.
    if (index < 0 || index >= _mockSlides.length) return null;
    return _mockSlides[index];
  }

  @override
  Future<void> ensurePointerSynced(String attemptId, int expectedIndex) async {
    // ensurePointerSynced: fuerza la posición interna `_questionPosition`
    // para que coincida con `expectedIndex`. Se usa al reanudar intentos
    // para que la siguiente llamada a `getNextSlideDto` devuelva la slide
    // correcta.
    final cur = _questionPosition[attemptId] ?? 0;
    if (cur != expectedIndex) {
      _questionPosition[attemptId] = expectedIndex;
    }
  }
}
