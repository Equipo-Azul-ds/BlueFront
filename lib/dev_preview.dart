import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/gameSession/application/dtos/multiplayer_session_dtos.dart';
import 'features/gameSession/application/dtos/multiplayer_socket_events.dart';
import 'features/gameSession/application/use_cases/multiplayer_session_usecases.dart';
import 'features/gameSession/domain/repositories/multiplayer_session_realtime.dart';
import 'features/gameSession/domain/repositories/multiplayer_session_repository.dart';
import 'features/gameSession/presentation/controllers/multiplayer_session_controller.dart';
import 'features/gameSession/presentation/pages/host_game.dart';
import 'features/gameSession/presentation/pages/host_lobby.dart';
import 'features/gameSession/presentation/pages/host_results_screen.dart';
import 'features/gameSession/presentation/pages/join_game.dart';
import 'features/gameSession/presentation/pages/player_lobby_screen.dart';
import 'features/gameSession/presentation/pages/player_question_results_screen.dart';
import 'features/gameSession/presentation/pages/player_question_screen.dart';
import 'features/gameSession/presentation/pages/player_results_screen.dart';
import 'features/report/application/use_cases/report_usecases.dart';
import 'features/report/domain/entities/report_model.dart';
import 'features/report/domain/repositories/reports_repository.dart';
import 'features/report/presentation/blocs/report_detail_bloc.dart';
import 'features/report/presentation/blocs/reports_list_bloc.dart';
import 'features/report/presentation/pages/report_detail_page.dart';
import 'features/report/presentation/pages/reports_list_page.dart';

void main() {
  runApp(const DevPreviewApp());
}

/// App de previsualización sin backend que inyecta un controlador mockeado
/// para poder navegar por las pantallas de gameSession y revisar UI.
class DevPreviewApp extends StatelessWidget {
  const DevPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose the preview controller as both its concrete type (for scenario helpers)
        // and the base type consumed by the existing pages.
        ChangeNotifierProvider<PreviewMultiplayerSessionController>(
          create: (_) => PreviewMultiplayerSessionController(),
        ),
        ProxyProvider<PreviewMultiplayerSessionController, MultiplayerSessionController>(
          update: (_, preview, __) => preview,
        ),
        Provider<ReportsRepository>(
          create: (_) => _PreviewReportsRepository(),
        ),
        ProxyProvider<ReportsRepository, GetMyResultsUseCase>(
          update: (_, repo, __) => GetMyResultsUseCase(repo),
        ),
        ProxyProvider<ReportsRepository, GetSessionReportUseCase>(
          update: (_, repo, __) => GetSessionReportUseCase(repo),
        ),
        ProxyProvider<ReportsRepository, GetMultiplayerResultUseCase>(
          update: (_, repo, __) => GetMultiplayerResultUseCase(repo),
        ),
        ProxyProvider<ReportsRepository, GetSingleplayerResultUseCase>(
          update: (_, repo, __) => GetSingleplayerResultUseCase(repo),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GameSession Preview',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
        home: const _PreviewHome(),
      ),
    );
  }
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<PreviewMultiplayerSessionController>();
    return Scaffold(
      appBar: AppBar(title: const Text('GameSession Preview')), 
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Elige la pantalla a previsualizar. El estado se inyecta con datos ficticios.'),
          const SizedBox(height: 16),
          _tile(
            context,
            title: 'Join Game',
            subtitle: 'Flujo de jugador: ingreso de PIN/QR',
            onTap: () {
              ctrl.setLobbyScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JoinGameScreen()),
              );
            },
          ),
          _tile(
            context,
            title: 'Player Lobby',
            onTap: () {
              ctrl.setLobbyScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlayerLobbyScreen()),
              );
            },
          ),
          _tile(
            context,
            title: 'Player Question',
            onTap: () {
              ctrl.setQuestionScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlayerQuestionScreen()),
              );
            },
          ),
          _tile(
            context,
            title: 'Player Question Result',
            onTap: () {
              ctrl.setPlayerResultScenario();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlayerQuestionResultsScreen(sequenceNumber: 1),
                ),
              );
            },
          ),
          _tile(
            context,
            title: 'Player Final Results',
            onTap: () {
              ctrl.setEndScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlayerResultsScreen()),
              );
            },
          ),
          const Divider(),
          _tile(
            context,
            title: 'Host Lobby',
            onTap: () {
              ctrl.setLobbyScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HostLobbyScreen(kahootId: 'preview-kahoot')),
              );
            },
          ),
          _tile(
            context,
            title: 'Host Question View',
            onTap: () {
              ctrl.setQuestionScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HostGameScreen()),
              );
            },
          ),
          _tile(
            context,
            title: 'Host Question Results',
            onTap: () {
              ctrl.setHostResultScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HostGameScreen()),
              );
            },
          ),
          _tile(
            context,
            title: 'Host Final Podium',
            onTap: () {
              ctrl.setEndScenario();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HostResultsScreen()),
              );
            },
          ),
          const Divider(),
          _tile(
            context,
            title: 'Reports list (preview)',
            subtitle: 'Mis reportes paginados',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (ctx) => ReportsListBloc(
                      getMyResultsUseCase: ctx.read<GetMyResultsUseCase>(),
                    ),
                    child: const ReportsListPage(),
                  ),
                ),
              );
            },
          ),
          _tile(
            context,
            title: 'Report detail (multi)',
            subtitle: 'Carga desde summary mock',
            onTap: () {
              final summary = _PreviewReportsRepository.sampleSummaries.first;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportDetailPage(summary: summary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, {required String title, String? subtitle, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Controlador mock que sobreescribe getters y métodos para exponer datos de muestra
/// sin necesidad de backend ni socket.
class PreviewMultiplayerSessionController extends MultiplayerSessionController {
  PreviewMultiplayerSessionController()
      : _realtime = _sharedRealtime,
        _repository = _sharedRepository,
        super(
          realtime: _sharedRealtime,
          initializeHostLobbyUseCase: InitializeHostLobbyUseCase(
            repository: _sharedRepository,
            realtime: _sharedRealtime,
          ),
          resolvePinFromQrTokenUseCase: ResolvePinFromQrTokenUseCase(
            repository: _sharedRepository,
          ),
          joinLobbyUseCase: JoinLobbyUseCase(realtime: _sharedRealtime),
          leaveSessionUseCase: LeaveSessionUseCase(realtime: _sharedRealtime),
          emitHostStartGameUseCase: EmitHostStartGameUseCase(realtime: _sharedRealtime),
          emitHostNextPhaseUseCase: EmitHostNextPhaseUseCase(realtime: _sharedRealtime),
          emitHostEndSessionUseCase: EmitHostEndSessionUseCase(realtime: _sharedRealtime),
          submitPlayerAnswerUseCase: SubmitPlayerAnswerUseCase(realtime: _sharedRealtime),
        ) {
    // Marca el socket como conectado para que la UI muestre estados activos.
    _realtime.seedConnected();
  }

  static final _PreviewRealtime _sharedRealtime = _PreviewRealtime();
  static final _PreviewSessionRepository _sharedRepository = _PreviewSessionRepository();

  final _PreviewRealtime _realtime;
  final _PreviewSessionRepository _repository;

  String _sessionPin = '246810';
  String _qrToken = 'mock-qr-token';
  String _quizTitle = 'Trivia de prueba';
  String _nickname = 'Previewer';
  SessionPhase _phase = SessionPhase.lobby;
  List<SessionPlayer> _players = const [
    SessionPlayer(playerId: 'p1', nickname: 'Ana'),
    SessionPlayer(playerId: 'p2', nickname: 'Bruno'),
    SessionPlayer(playerId: 'p3', nickname: 'Carla'),
  ];
  QuestionStartedEvent? _question;
  HostResultsEvent? _hostResults;
  PlayerResultsEvent? _playerResults;
  HostGameEndEvent? _hostGameEnd;
  PlayerGameEndEvent? _playerGameEnd;
  DateTime? _questionStartedAt;
  int _questionSeq = 1;
  int _hostGameEndSeq = 1;
  int _playerGameEndSeq = 1;

  @override
  String? get sessionPin => _sessionPin;
  @override
  String? get qrToken => _qrToken;
  @override
  String? get quizTitle => _quizTitle;
  @override
  String? get currentNickname => _nickname;
  @override
  MultiplayerSocketStatus get socketStatus => MultiplayerSocketStatus.connected;
  @override
  List<SessionPlayer> get lobbyPlayers => List.unmodifiable(_players);
  @override
  SessionPhase get phase => _phase;
  @override
  QuestionStartedEvent? get currentQuestionDto => _question;
  @override
  HostResultsEvent? get hostResultsDto => _hostResults;
  @override
  PlayerResultsEvent? get playerResultsDto => _playerResults;
  @override
  HostGameEndEvent? get hostGameEndDto => _hostGameEnd;
  @override
  PlayerGameEndEvent? get playerGameEndDto => _playerGameEnd;
  @override
  DateTime? get questionStartedAt => _questionStartedAt;
  @override
  int get questionSequence => _questionSeq;
  @override
  int get hostGameEndSequence => _hostGameEndSeq;
  @override
  int get playerGameEndSequence => _playerGameEndSeq;
  @override
  int? get hostAnswerSubmissions => _hostResults?.stats.totalAnswers;
  @override
  bool get canHostStartGame => true;

  @override
  Future<void> initializeHostLobby({required String kahootId, String? jwt}) async {
    setLobbyScenario();
  }

  @override
  Future<void> joinLobby({required String pin, required String nickname, String? jwt}) async {
    _sessionPin = pin;
    _nickname = nickname;
    setLobbyScenario();
  }

  @override
  Future<void> leaveSession() async {
    setLobbyScenario();
  }

  @override
  void emitHostStartGame() {
    setQuestionScenario();
  }

  @override
  void emitHostNextPhase() {
    if (_phase == SessionPhase.question) {
      setHostResultScenario();
    } else if (_phase == SessionPhase.results) {
      setEndScenario();
    }
  }

  @override
  void emitHostEndSession() {
    setEndScenario();
  }

  void setLobbyScenario() {
    _phase = SessionPhase.lobby;
    _question = null;
    _hostResults = null;
    _playerResults = null;
    _hostGameEnd = null;
    _playerGameEnd = null;
    _questionStartedAt = null;
    _questionSeq = 1;
    _players = const [
      SessionPlayer(playerId: 'p1', nickname: 'Ana'),
      SessionPlayer(playerId: 'p2', nickname: 'Bruno'),
      SessionPlayer(playerId: 'p3', nickname: 'Carla'),
    ];
    notifyListeners();
  }

  void setQuestionScenario() {
    _phase = SessionPhase.question;
    _questionSeq += 1;
    _questionStartedAt = DateTime.now();
    _question = QuestionStartedEvent(
      state: 'question',
      slide: SlideData(
        id: 'slide-1',
        position: 1,
        slideType: 'quiz',
        timeLimitSeconds: 20,
        questionText: '¿Cuál es la capital de Francia?',
        imageUrl: null,
        pointsValue: 1000,
        isMultiSelect: false,
        maxSelections: 1,
        options: const [
          SlideOption(id: 'A', text: 'París'),
          SlideOption(id: 'B', text: 'Londres'),
          SlideOption(id: 'C', text: 'Roma'),
          SlideOption(id: 'D', text: 'Berlín'),
        ],
      ),
      timeRemainingMs: 18000,
      hasAnswered: false,
    );
    _hostResults = null;
    _playerResults = null;
    _hostGameEnd = null;
    _playerGameEnd = null;
    notifyListeners();
  }

  void setHostResultScenario() {
    _phase = SessionPhase.results;
    _hostResults = HostResultsEvent(
      state: 'results',
      correctAnswerIds: const ['A'],
      leaderboard: [
        LeaderboardEntry(rank: 1, previousRank: 2, playerId: 'p1', nickname: 'Ana', score: 2300),
        LeaderboardEntry(rank: 2, previousRank: 1, playerId: 'p2', nickname: 'Bruno', score: 2100),
        LeaderboardEntry(rank: 3, previousRank: 3, playerId: 'p3', nickname: 'Carla', score: 1800),
      ],
      stats: ResultsStats(totalAnswers: 3, distribution: const {'A': 2, 'B': 1}),
      progress: ProgressInfo(current: 1, total: 3, isLastSlide: false),
    );
    _hostGameEnd = null;
    _playerGameEnd = null;
    notifyListeners();
  }

  void setPlayerResultScenario() {
    _phase = SessionPhase.results;
    _playerResults = PlayerResultsEvent(
      isCorrect: true,
      pointsEarned: 600,
      totalScore: 2300,
      rank: 1,
      previousRank: 2,
      streak: 3,
      correctAnswerIds: const ['A'],
      progress: ProgressInfo(current: 1, total: 3, isLastSlide: false),
      message: '¡Buen trabajo!',
    );
    notifyListeners();
  }

  void setEndScenario() {
    _phase = SessionPhase.end;
    _hostGameEndSeq += 1;
    _playerGameEndSeq += 1;
    _hostGameEnd = HostGameEndEvent(
      state: 'end',
      finalPodium: [
        LeaderboardEntry(rank: 1, previousRank: 2, playerId: 'p1', nickname: 'Ana', score: 4500),
        LeaderboardEntry(rank: 2, previousRank: 1, playerId: 'p2', nickname: 'Bruno', score: 3800),
        LeaderboardEntry(rank: 3, previousRank: 3, playerId: 'p3', nickname: 'Carla', score: 3200),
      ],
      winner: LeaderboardEntry(rank: 1, previousRank: 2, playerId: 'p1', nickname: 'Ana', score: 4500),
      totalParticipants: 3,
      totalQuestions: 3,
    );
    _playerGameEnd = PlayerGameEndEvent(
      state: 'end',
      rank: 1,
      totalScore: 4500,
      isPodium: true,
      isWinner: true,
      finalStreak: 5,
      totalQuestions: 3,
      correctAnswers: 3,
      answers: const [
        PlayerAnswerSummary(index: 0, wasCorrect: true),
        PlayerAnswerSummary(index: 1, wasCorrect: true),
        PlayerAnswerSummary(index: 2, wasCorrect: true),
      ],
      finalPodium: [
        LeaderboardEntry(rank: 1, previousRank: 2, playerId: 'p1', nickname: 'Ana', score: 4500),
        LeaderboardEntry(rank: 2, previousRank: 1, playerId: 'p2', nickname: 'Bruno', score: 3800),
        LeaderboardEntry(rank: 3, previousRank: 3, playerId: 'p3', nickname: 'Carla', score: 3200),
      ],
    );
    notifyListeners();
  }
}

class _PreviewRealtime implements MultiplayerSessionRealtime {
  final _statusController = StreamController<MultiplayerSocketStatus>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  void seedConnected() {
    _statusController.add(MultiplayerSocketStatus.connected);
  }

  @override
  Future<void> connect(MultiplayerSocketParams params) async {
    _statusController.add(MultiplayerSocketStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    _statusController.add(MultiplayerSocketStatus.disconnected);
  }

  @override
  Stream<MultiplayerSocketStatus> get statusStream => _statusController.stream;

  @override
  Stream<Object> get errors => _errorController.stream;

  @override
  bool get isConnected => true;

  @override
  Stream<T> listenToServerEvent<T>(String eventName) {
    return const Stream.empty();
  }

  @override
  void emitClientReady() {}

  @override
  void emitPlayerJoin(PlayerJoinPayload payload) {}

  @override
  void emitHostStartGame() {}

  @override
  void emitPlayerSubmitAnswer(PlayerSubmitAnswerPayload payload) {}

  @override
  void emitHostNextPhase() {}

  @override
  void emitHostEndSession() {}
}

class _PreviewSessionRepository implements MultiplayerSessionRepository {
  @override
  Future<CreateSessionResponse> createSession(CreateSessionRequest request) async {
    return CreateSessionResponse(
      sessionPin: '246810',
      qrToken: 'preview-qr-token',
      quizTitle: 'Trivia de prueba',
      coverImageUrl: null,
      theme: null,
    );
  }

  @override
  Future<QrTokenLookupResponse> getSessionPinFromQr(String qrToken) async {
    return QrTokenLookupResponse(sessionPin: '246810', sessionId: 'session-preview');
  }
}

class _PreviewReportsRepository implements ReportsRepository {
  static final List<ReportSummary> sampleSummaries = <ReportSummary>[
    ReportSummary(
      kahootId: 'kahoot-1',
      gameId: 'session-001',
      gameType: GameType.multiplayer,
      title: 'Trivia de historia',
      completionDate: DateTime(2024, 5, 20, 18, 30),
      finalScore: 4300,
      rankingPosition: 1,
    ),
    ReportSummary(
      kahootId: 'kahoot-2',
      gameId: 'attempt-abc',
      gameType: GameType.singleplayer,
      title: 'Geografía exprés',
      completionDate: DateTime(2024, 6, 12, 14, 10),
      finalScore: 2750,
      rankingPosition: null,
    ),
  ];

  static final SessionReport sampleSessionReport = SessionReport(
    reportId: 'report-001',
    sessionId: 'session-001',
    title: 'Trivia de historia',
    executionDate: DateTime(2024, 5, 20, 18, 30),
    playerRanking: [
      PlayerRankingEntry(position: 1, username: 'Ana', score: 4300, correctAnswers: 9),
      PlayerRankingEntry(position: 2, username: 'Bruno', score: 3900, correctAnswers: 8),
      PlayerRankingEntry(position: 3, username: 'Carla', score: 3200, correctAnswers: 7),
    ],
    questionAnalysis: [
      QuestionAnalysisEntry(questionIndex: 1, questionText: 'Capital de Francia', correctPercentage: 92),
      QuestionAnalysisEntry(questionIndex: 2, questionText: 'Año de independencia', correctPercentage: 61),
      QuestionAnalysisEntry(questionIndex: 3, questionText: 'Río más largo', correctPercentage: 74),
    ],
  );

  static final PersonalResult sampleMultiResult = PersonalResult(
    kahootId: 'kahoot-1',
    title: 'Trivia de historia',
    userId: 'user-preview',
    finalScore: 4300,
    correctAnswers: 9,
    totalQuestions: 10,
    averageTimeMs: 5200,
    questionResults: [
      QuestionResultEntry(
        questionIndex: 1,
        questionText: 'Capital de Francia',
        isCorrect: true,
        answerText: ['París'],
        answerMediaIds: <String>[],
        timeTakenMs: 3800,
      ),
      QuestionResultEntry(
        questionIndex: 2,
        questionText: 'Año de independencia',
        isCorrect: false,
        answerText: ['1810'],
        answerMediaIds: <String>[],
        timeTakenMs: 6100,
      ),
    ],
    rankingPosition: 1,
  );

  static final PersonalResult sampleSingleResult = PersonalResult(
    kahootId: 'kahoot-2',
    title: 'Geografía exprés',
    userId: 'user-preview',
    finalScore: 2750,
    correctAnswers: 6,
    totalQuestions: 8,
    averageTimeMs: 4800,
    questionResults: [
      QuestionResultEntry(
        questionIndex: 1,
        questionText: 'Monte más alto',
        isCorrect: true,
        answerText: ['Everest'],
        answerMediaIds: <String>[],
        timeTakenMs: 4100,
      ),
      QuestionResultEntry(
        questionIndex: 2,
        questionText: 'Río más largo',
        isCorrect: true,
        answerText: ['Nilo'],
        answerMediaIds: <String>[],
        timeTakenMs: 5200,
      ),
    ],
    rankingPosition: null,
  );

  @override
  Future<MyResultsResponse> fetchMyResults({int limit = 20, int page = 1}) async {
    return MyResultsResponse(
      results: sampleSummaries,
      meta: PaginationMeta(
        totalItems: sampleSummaries.length,
        currentPage: page,
        totalPages: 1,
        limit: limit,
      ),
    );
  }

  @override
  Future<SessionReport> fetchSessionReport(String sessionId) async {
    return sampleSessionReport;
  }

  @override
  Future<PersonalResult> fetchMultiplayerResult(String sessionId) async {
    return sampleMultiResult;
  }

  @override
  Future<PersonalResult> fetchSingleplayerResult(String attemptId) async {
    return sampleSingleResult;
  }
}
