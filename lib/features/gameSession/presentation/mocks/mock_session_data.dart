const String mockSessionPin = '482913';
const String mockQuizTitle = 'DDD Trivia';
const String mockDefaultNickname = 'Tú';

const List<String> mockLobbyPlayers = [
  'Zuri',
  'Benito',
  'Ari',
  'Lola',
  'Kenji',
  'Rafa',
  'Miu',
  'Tú',
];

const List<Map<String, dynamic>> mockSessionQuestions = [
  {
    'id': 'q1',
    'question': '¿Qué hace especial a un bounded context?',
    'context': 'DDD Intro',
    'time': 20,
    'media': null,
    'answers': [
      {'text': 'Permite que cada equipo hable su idioma', 'correct': true},
      {'text': 'Obliga a usar microservicios', 'correct': false},
      {'text': 'Elimina dependencias externas', 'correct': false},
      {'text': 'Solo aplica en backend', 'correct': false},
    ],
    'stats': [14, 3, 2, 1],
  },
  {
    'id': 'q2',
    'question': '¿Qué medimos en el discovery disciplinado?',
    'context': 'Discovery',
    'time': 25,
    'media': null,
    'answers': [
      {'text': 'Riesgos del experimento', 'correct': true},
      {'text': 'Popularidad del framework', 'correct': false},
      {'text': 'Cantidad de deploys por día', 'correct': false},
      {'text': 'Número de squads', 'correct': false},
    ],
    'stats': [18, 2, 1, 0],
  },
];

const List<Map<String, dynamic>> mockSessionStandings = [
  {'name': 'Lola', 'score': 2100, 'correct': 4, 'avgTime': 6.2},
  {'name': 'Rafa', 'score': 1980, 'correct': 3, 'avgTime': 7.1},
  {'name': 'Kenji', 'score': 1500, 'correct': 2, 'avgTime': 8.8},
  {'name': 'Zuri', 'score': 1200, 'correct': 1, 'avgTime': 9.4},
];

List<bool?> buildInitialAnswerProgress() =>
    List<bool?>.filled(mockSessionQuestions.length, null);
