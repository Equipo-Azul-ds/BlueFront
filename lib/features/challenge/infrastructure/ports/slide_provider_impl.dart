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

  final Map<String, List<SlideDTO>> _quizBanks = {
    'mock_quiz_1': [
      SlideDTO(
        slideId: 'mock1_q1',
        questionText: '¿Cuánto es 2 + 2?',
        questionType: 'quiz',
        timeLimitSeconds: 20,
        options: [
          SlideOptionDTO(index: 0, text: '3'),
          SlideOptionDTO(index: 1, text: '4'),
          SlideOptionDTO(index: 2, text: '5'),
          SlideOptionDTO(index: 3, text: '6'),
        ],
        mediaUrl: null,
      ),
      SlideDTO(
        slideId: 'mock1_q2',
        questionText: '¿Cuál es la capital de Francia?',
        questionType: 'quiz',
        timeLimitSeconds: 20,
        options: [
          SlideOptionDTO(index: 0, text: 'París'),
          SlideOptionDTO(index: 1, text: 'Londres'),
          SlideOptionDTO(index: 2, text: 'Berlín'),
        ],
        mediaUrl: null,
      ),
      SlideDTO(
        slideId: 'mock1_q3',
        questionText: 'Marte es conocido como el Planeta Rojo.',
        questionType: 'true_false',
        timeLimitSeconds: 20,
        options: [
          SlideOptionDTO(index: 0, text: 'Verdadero'),
          SlideOptionDTO(index: 1, text: 'Falso'),
        ],
        mediaUrl: 'assets/images/pia04304-mars.jpg',
      ),
      SlideDTO(
        slideId: 'mock1_q4',
        questionText: '¿Cuál es el punto de ebullición del agua (°C)?',
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
        slideId: 'mock1_q5',
        questionText:
            '¿Qué lenguaje se usa principalmente para desarrollar con Flutter?',
        questionType: 'quiz',
        timeLimitSeconds: 20,
        options: [
          SlideOptionDTO(index: 0, text: 'Java'),
          SlideOptionDTO(index: 1, text: 'Dart'),
          SlideOptionDTO(index: 2, text: 'Kotlin'),
        ],
        mediaUrl: null,
      ),
    ],
    'mock_quiz_ddd': [
      SlideDTO(
        slideId: 'ddd_q1',
        questionText: '¿Qué significa Domain-Driven Design?',
        questionType: 'quiz',
        timeLimitSeconds: 25,
        options: [
          SlideOptionDTO(index: 0, text: 'Diseño dirigido por datos'),
          SlideOptionDTO(index: 1, text: 'Diseño orientado al dominio'),
          SlideOptionDTO(index: 2, text: 'Desarrollo dirigido al despliegue'),
          SlideOptionDTO(index: 3, text: 'Diseño determinista digital'),
        ],
        mediaUrl: null,
      ),
      SlideDTO(
        slideId: 'ddd_q2',
        questionText:
            '¿Cuál es el propósito del Lenguaje Ubicuo en DDD?',
        questionType: 'quiz',
        timeLimitSeconds: 25,
        options: [
          SlideOptionDTO(index: 0, text: 'Unificar la comunicación del equipo'),
          SlideOptionDTO(index: 1, text: 'Definir la capa de infraestructura'),
          SlideOptionDTO(index: 2, text: 'Optimizar las consultas SQL'),
          SlideOptionDTO(index: 3, text: 'Escribir documentación técnica'),
        ],
        mediaUrl: null,
      ),
      SlideDTO(
        slideId: 'ddd_q3',
        questionText:
            '¿En qué capa se concentra la lógica del dominio en DDD?',
        questionType: 'quiz',
        timeLimitSeconds: 25,
        options: [
          SlideOptionDTO(index: 0, text: 'Capa de Aplicación'),
          SlideOptionDTO(index: 1, text: 'Capa de Dominio'),
          SlideOptionDTO(index: 2, text: 'Infraestructura'),
          SlideOptionDTO(index: 3, text: 'Presentación'),
        ],
        mediaUrl: null,
      ),
      SlideDTO(
        slideId: 'ddd_q4',
        questionText:
            '¿Qué describe un Bounded Context dentro de un dominio?',
        questionType: 'quiz',
        timeLimitSeconds: 25,
        options: [
          SlideOptionDTO(index: 0, text: 'Una base de datos exclusiva'),
          SlideOptionDTO(index: 1, text: 'Un límite claro de modelo y lenguaje'),
          SlideOptionDTO(index: 2, text: 'Un microservicio desplegado'),
          SlideOptionDTO(index: 3, text: 'Un backlog de historias'),
        ],
        mediaUrl: null,
      ),
      SlideDTO(
        slideId: 'ddd_q5',
        questionText:
            '¿Qué patrón se usa para persistir agregados en DDD?',
        questionType: 'quiz',
        timeLimitSeconds: 25,
        options: [
          SlideOptionDTO(index: 0, text: 'Repositorio'),
          SlideOptionDTO(index: 1, text: 'Strategy'),
          SlideOptionDTO(index: 2, text: 'Observer'),
          SlideOptionDTO(index: 3, text: 'Decorator'),
        ],
        mediaUrl: null,
      ),
    ],
  };

  // Mapa de respuestas correctas (infra/mock)
  final Map<String, int> _correctAnswers = {
    'mock1_q1': 1,
    'mock1_q2': 0,
    'mock1_q3': 0,
    'mock1_q4': 1,
    'mock1_q5': 1,
    'ddd_q1': 1,
    'ddd_q2': 0,
    'ddd_q3': 1,
    'ddd_q4': 1,
    'ddd_q5': 0,
  };

  @override
  Future<SlideDTO?> getNextSlideDto(String attemptId) async {
    // getNextSlideDto: devuelve la siguiente slide para `attemptId` y
    // avanza el puntero interno. Simula una pequeña latencia para emular
    // una llamada de red/IO.
    // IMPORTANTE: este método avanza el puntero; no usarlo si se desea
    // solamente obtener metadata sin afectar el flujo (usar `peekSlideDto`).

    final slides = _slidesForAttempt(attemptId);
    final idx = _questionPosition[attemptId] ?? 0;
    if (idx >= slides.length) return null;

    final slide = slides[idx];
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
    final slides = _slidesForAttempt(attemptId);
    if (index < 0 || index >= slides.length) return null;
    return slides[index];
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

  List<SlideDTO> _slidesForAttempt(String attemptId) {
    final quizId = _quizIdFromAttempt(attemptId);
    return _quizBanks[quizId] ?? _quizBanks.values.first;
  }

  String _quizIdFromAttempt(String attemptId) {
    const marker = '_attempt_';
    if (attemptId.contains(marker)) {
      final quizId = attemptId.split(marker).first;
      if (_quizBanks.containsKey(quizId)) {
        return quizId;
      }
    }
    return 'mock_quiz_1';
  }
}
