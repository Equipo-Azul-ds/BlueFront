import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart' as staggered;
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../features/media/presentation/blocs/media_editor_bloc.dart';
import '../core/constants/colors.dart';
import '../features/kahoot/presentation/blocs/quiz_editor_bloc.dart';
import '../features/kahoot/application/dtos/create_quiz_dto.dart';
import '../features/kahoot/domain/entities/Quiz.dart';
import '../common_widgets/kahoot_card.dart';


class DashboardPage extends StatefulWidget{
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loadingUserQuizzes = false;
  final Map<String, Uint8List?> _coverCache = {};
  final Map<String, String?> _coverUrlCache = {};
  final Set<String> _fetchingCover = {};
  // Signatures of quizzes we've already inserted from navigation args during this session
  final Set<String> _insertedQuizSignatures = {};
  String _quizCacheKey(String quizId) => '__quiz__${quizId}';

  @override
  void initState() {
    super.initState();
    // Cargar cuestionarios de usuario al ingresar (usa un ID de autor de marcador de posición)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
      if (quizBloc.userQuizzes == null) {
        // Attempt to load user quizzes. If there is no currentQuiz.authorId,
        // fallback to a default test author id so that the Dashboard shows
        // quizzes created during development/testing.
        const defaultTestAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
        var authorIdCandidate = quizBloc.currentQuiz?.authorId ?? '';
        if (authorIdCandidate.isEmpty) authorIdCandidate = defaultTestAuthorId;

        setState(() => _loadingUserQuizzes = true);
        try {
          await quizBloc.loadUserQuizzes(authorIdCandidate);
        } catch (e) {
          // Log but do not crash the UI if backend rejects the id.
          print('[dashboard] loadUserQuizzes error for author=$authorIdCandidate -> $e');
        }
        if (mounted) setState(() => _loadingUserQuizzes = false);
      }
    });
  }

  Future<void> _fetchCoverIfNeeded(String mediaId) async {
    print('[dashboard] _fetchCoverIfNeeded -> mediaId=$mediaId');
    try {
      final mediaBloc = Provider.of<MediaEditorBloc>(context, listen: false);
      final response = await mediaBloc.getMedia(mediaId);
      final mediaPath = (response.media as dynamic).path ?? '';
      print('[dashboard] getMedia for $mediaId -> path=$mediaPath fileLen=${response.file?.length ?? 0}');

      if (response.file != null && response.file!.isNotEmpty) {
        _coverCache[mediaId] = response.file;
        print('[dashboard] cached bytes for $mediaId (len=${response.file!.length})');
      } else if (mediaPath is String && mediaPath.startsWith('http')) {
        _coverUrlCache[mediaId] = mediaPath;
        print('[dashboard] cached url for $mediaId -> $mediaPath');
      } else if (mediaPath is String && mediaPath.isNotEmpty) {
        // Try candidate URLs constructed from baseUrl providers
        String? baseUrl;
        try {
          final mediaRepo = Provider.of<dynamic>(context, listen: false);
          baseUrl = (mediaRepo as dynamic).baseUrl;
        } catch (_) {}
        if (baseUrl == null) {
          try {
            final storageRepo = Provider.of<dynamic>(context, listen: false);
            baseUrl = (storageRepo as dynamic).baseUrl;
          } catch (_) {}
        }

        final candidates = <String>[];
        if (baseUrl != null) {
          candidates.add('$baseUrl/storage/file/$mediaPath');
          candidates.add('$baseUrl/storage/file/${Uri.encodeComponent(mediaPath)}');
          candidates.add('$baseUrl/media/$mediaId/file');
          candidates.add('$baseUrl/media/file/$mediaId');
        }
        if (mediaPath.startsWith('http')) candidates.add(mediaPath);

        print('[dashboard] trying candidate URLs for $mediaId -> $candidates');
        for (final url in candidates) {
          try {
            final resp = await http.get(Uri.parse(url));
            print('[dashboard] GET $url -> ${resp.statusCode}');
            if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
              _coverUrlCache[mediaId] = url;
              break;
            }
          } catch (ex) {
            print('[dashboard] GET exception $url -> $ex');
          }
        }

        if (!_coverCache.containsKey(mediaId) && !_coverUrlCache.containsKey(mediaId)) {
          _coverCache[mediaId] = null;
        }
      } else {
        _coverCache[mediaId] = null;
      }
    } catch (e, st) {
      print('[dashboard] Exception fetching cover $mediaId -> $e');
      print(st);
      _coverCache[mediaId] = null;
    } finally {
      _fetchingCover.remove(mediaId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, Quiz q) async {
    final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text('Eliminar Quiz'),
        content: Text('¿Estás seguro que deseas eliminar "${q.title}" de forma permanente?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      );
    });

    if (confirmed == true) {
      try {
        // Only call backend delete if the quiz is not marked local. Frontend should
        // not infer backend semantics from UUID formats — use explicit `isLocal` flag.
        if (q.isLocal) {
          // Local-only quiz — remove locally without calling API.
          // Do NOT remove by plain `quizId == ''` because many local items
          // may have empty ids; prefer identity, then fallback to title+createdAt.
          if (quizBloc.userQuizzes != null) {
            quizBloc.userQuizzes!.removeWhere((item) {
              if (identical(item, q)) return true;
              // If both have non-empty ids, match by id
              if (item.quizId.isNotEmpty && q.quizId.isNotEmpty && item.quizId == q.quizId) return true;
              // If ids are empty, use a stronger heuristic: title + createdAt timestamp
              if (item.quizId.isEmpty && q.quizId.isEmpty && item.title == q.title && item.createdAt.toIso8601String() == q.createdAt.toIso8601String()) return true;
              return false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz eliminado localmente')));
          if (mounted) setState(() {});
          return;
        }

        print('[dashboard] requesting delete for quizId=${q.quizId}');
        await quizBloc.deleteQuiz(q.quizId);
        if (quizBloc.errorMessage != null) {
          print('[dashboard] delete returned error: ${quizBloc.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${quizBloc.errorMessage}')));
          return;
        }
        // Remove from local list if present
        if (quizBloc.userQuizzes != null) {
          quizBloc.userQuizzes!.removeWhere((item) {
            if (item.quizId.isNotEmpty && q.quizId.isNotEmpty && item.quizId == q.quizId) return true;
            if (identical(item, q)) return true;
            if (item.quizId.isEmpty && q.quizId.isEmpty && item.title == q.title && item.createdAt.toIso8601String() == q.createdAt.toIso8601String()) return true;
            return false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz eliminado')));
        if (mounted) setState(() {});
      } catch (e) {
        print('[dashboard] Exception during delete flow: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _showQuizOptions(BuildContext context, Quiz q) async {
    final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
    final quizKey = _quizCacheKey(q.quizId);
    final mediaKey = q.coverImageUrl;
    Uint8List? bytes = mediaKey != null && !mediaKey.startsWith('http') ? _coverCache[mediaKey] : null;
    bytes ??= _coverCache[quizKey];
    String? url = mediaKey != null ? (_coverUrlCache[mediaKey] ?? (mediaKey.startsWith('http') ? mediaKey : null)) : _coverUrlCache[quizKey];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (_, controller) => Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
                child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                        clipBehavior: Clip.hardEdge,
                        child: bytes != null
                          ? Image.memory(bytes, fit: BoxFit.cover)
                          : (url != null ? Image.network(url, fit: BoxFit.cover) : (q.coverImageUrl != null && q.coverImageUrl!.startsWith('http') ? Image.network(q.coverImageUrl!, fit: BoxFit.cover) : Center(child: Icon(Icons.image)))),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(q.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    // Close the bottom sheet first to avoid triggering bloc notifications
                                    Navigator.of(ctx).pop();
                                    try {
                                      if (q.quizId.isNotEmpty && !q.isLocal) {
                                        // Load full quiz into the bloc (will update currentQuiz)
                                        await quizBloc.loadQuiz(q.quizId);
                                      } else {
                                        // Use provided object for local items; schedule setCurrentQuiz after frame
                                        WidgetsBinding.instance.addPostFrameCallback((_) => quizBloc.setCurrentQuiz(q));
                                      }
                                      Navigator.pushNamed(context, '/create');
                                    } catch (e) {
                                      print('[dashboard] failed to load quiz for edit id=${q.quizId} -> $e');
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando el quiz para edición: $e')));
                                    }
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(q.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 8),
                            // Template / Theme info
                            Text('Tema: ${_themeName(q.themeId)}', style: TextStyle(color: Colors.grey[700])),
                            if (q.templateId != null) SizedBox(height: 4),
                            if (q.templateId != null) Text('Plantilla: ${q.templateId}', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Buttons row (three buttons as requested). For now they perform delete.
                  Row(
                    children: [
                      // Editar: principal
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Close bottom sheet first to avoid notifyDuringBuild
                              Navigator.of(ctx).pop();
                              try {
                                if (q.quizId.isNotEmpty && !q.isLocal) {
                                  await quizBloc.loadQuiz(q.quizId);
                                } else {
                                  WidgetsBinding.instance.addPostFrameCallback((_) => quizBloc.setCurrentQuiz(q));
                                }
                                Navigator.pushNamed(context, '/create');
                              } catch (e) {
                                print('[dashboard] failed to load quiz for edit (button) id=${q.quizId} -> $e');
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando el quiz para edición: $e')));
                              }
                            },
                            icon: Icon(Icons.edit, size: 20),
                            label: Text('Editar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Duplicar: botón compacto outlined con icono y pequeño texto
                      SizedBox(
                        width: 72,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () async {
                            // Perform a real POST to create a duplicated quiz on the backend.
                            Navigator.of(ctx).pop();
                            
                            const defaultTestAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
                            final authorIdCandidate = (q.authorId.isEmpty || q.authorId.contains('placeholder')) ? defaultTestAuthorId : q.authorId;

                            // Map questions & answers into Create* DTOs (new ids are handled server-side, but we generate unique local ids for safety)
                            final mappedQuestions = q.questions.map((origQ) {
                              final answers = origQ.answers.map((a) => CreateAnswerDto(answerText: a.text, answerImage: a.mediaUrl, isCorrect: a.isCorrect)).toList();
                              return CreateQuestionDto(
                                questionText: origQ.text,
                                mediaUrl: origQ.mediaUrl,
                                questionType: origQ.type,
                                timeLimit: origQ.timeLimit,
                                points: origQ.points,
                                answers: answers,
                              );
                            }).toList();

                            final dto = CreateQuizDto(
                              authorId: authorIdCandidate,
                              title: '${q.title} (copia)',
                              description: q.description,
                              coverImage: q.coverImageUrl,
                              visibility: q.visibility,
                              status: q.status,
                              category: q.category,
                              themeId: q.themeId,
                              questions: mappedQuestions,
                            );

                            try {
                              await quizBloc.createQuiz(dto);
                              if (quizBloc.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al duplicar: ${quizBloc.errorMessage}')));
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz duplicado y creado')));
                              if (mounted) setState(() {});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al duplicar: $e')));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.copy, size: 18), SizedBox(width: 6), Flexible(child: Text('Dup', style: TextStyle(fontSize: 12)))],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Eliminar: botón compacto
                      SizedBox(
                        width: 96,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () async { Navigator.of(ctx).pop(); await _confirmAndDelete(context, q); },
                          icon: Icon(Icons.delete, size: 18),
                          label: Text('Eliminar', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  String _themeName(String? id) {
    if (id == null || id.isEmpty) return '—';
    final map = {
      'f1986c62-7dc1-47c5-9a1f-03d34043e8f4': 'Estándar',
      'd2ad3a12-4f1b-4c3e-9f2a-1a2b3c4d5e6f': 'Summer',
      'a3b9c8d7-1234-4ef0-9abc-0d1e2f3a4b5c': 'Spring',
      'b4c2d1e0-5678-49ab-8cde-9f0a1b2c3d4e': 'Winter',
      'c5d3e2f1-9abc-4def-8a1b-2c3d4e5f6a7b': 'Autumn',
      'e6f4a3b2-0f1e-4a5b-9cde-3b4c5d6e7f8a': 'Support Ukraine',
    };
    return map[id] ?? id;
  }

  // no-op

  @override
  Widget build(BuildContext context){
    // Obtener el bloc si es necesario en el futuro
    final quizBloc = Provider.of<QuizEditorBloc>(context);
    // Si el navegador pasó un cuestionario creado como argumento, se inserta en userQuizzes 
    //para que sea visible inmediatamente sin llamar al backend.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Quiz) {
      quizBloc.userQuizzes ??= [];
      final incoming = args;
      print('[dashboard] nav arg received: quizId=${incoming.quizId} title=${incoming.title} isLocal=${incoming.isLocal}');
      // Build a lightweight signature to detect repeated navigation inserts.
      final sigParts = [incoming.title.trim(), incoming.createdAt.toIso8601String(), incoming.coverImageUrl ?? ''];
      final signature = sigParts.join('|');
      print('[dashboard] received nav arg quiz signature=$signature');

      if (_insertedQuizSignatures.contains(signature)) {
        print('[dashboard] skipping insert: signature already seen');
      } else {
        Quiz toInsert = incoming;
        // Do NOT mark an incoming quiz as a local copy just because its id
        // is empty — only treat it as local if it was explicitly created
        // locally (incoming.isLocal == true). This ensures newly-created
        // quizzes that come back via navigation are shown as normal items.
        if (incoming.isLocal == true) {
          toInsert = Quiz(
            quizId: incoming.quizId,
            authorId: incoming.authorId,
            title: incoming.title,
            description: incoming.description,
            visibility: incoming.visibility,
            status: incoming.status,
            category: incoming.category,
            themeId: incoming.themeId,
            templateId: incoming.templateId,
            coverImageUrl: incoming.coverImageUrl,
            isLocal: true,
            createdAt: incoming.createdAt,
            questions: incoming.questions,
          );
        }

        // Always insert a fresh instance into the user's list to avoid later
        // accidental mutations via shared references.
        final candidate = Quiz(
          quizId: toInsert.quizId,
          authorId: toInsert.authorId,
          title: toInsert.title,
          description: toInsert.description,
          visibility: toInsert.visibility,
          status: toInsert.status,
          category: toInsert.category,
          themeId: toInsert.themeId,
          templateId: toInsert.templateId,
          coverImageUrl: toInsert.coverImageUrl,
          isLocal: toInsert.isLocal,
          createdAt: toInsert.createdAt,
          questions: List.from(toInsert.questions),
        );

        final exists = quizBloc.userQuizzes!.any((q) => q.quizId == candidate.quizId && q.title == candidate.title);
        if (!exists) {
          quizBloc.userQuizzes!.insert(0, candidate);
          _insertedQuizSignatures.add(signature);
          print('[dashboard] inserted quiz from nav args: id=${candidate.quizId} title=${candidate.title}');
        } else {
          print('[dashboard] not inserting: matching quiz already in list');
        }
      }
    }

    //Datos simualdos que posteriormente se reemplazaran con la api
      final recentKahoots = [
        Quiz(
          quizId: '1',
          authorId: 'Massiel',
          title: 'Arquitectura Hexagonal',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
        Quiz(
          quizId: '2',
          authorId: 'Jose',
          title: 'Desarrollo de software',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
      ];

      final recommendedKahoots = [
        Quiz(
          quizId: '3',
          authorId: 'Massiel',
          title: 'Seguimos en prueba',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
        Quiz(
          quizId: '4',
          authorId: 'Jose',
          title: 'hOLA ESTO ES UNA PRUEBA',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
      ];

      final TextEditingController pinController = TextEditingController();

    

    return Scaffold(
    backgroundColor: AppColor.background,
    body: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.of(context).size;
          // Limitar la altura del header para evitar tamaños enormes al hacer overscroll
          double headerHeight = min(constraints.maxHeight * 0.45, screenSize.height * 0.45);
          // Asegurar un minimo para que el header no colapse en pantallas pequeñas
          headerHeight = max(headerHeight, screenSize.height * 0.22);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: headerHeight,
                  child: Container(
                    padding: EdgeInsets.all(constraints.maxWidth * 0.05), 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColor.primary, AppColor.secundary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),

                    
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: headerHeight * 0.06),
                        // Colocar el logo arriba del saludo y alineado a la izquierda
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo a la izquierda, arriba del texto
                            Image.asset(
                              'assets/images/logo.png',
                              width: (constraints.maxWidth * 0.12).clamp(40.0, 80.0),
                              height: (constraints.maxWidth * 0.12).clamp(40.0, 80.0),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: constraints.maxWidth * 0.04),
                            // Textos (Hola, Jugador! y subtitulo)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'Hola, Jugador!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: constraints.maxWidth * 0.07,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Listo para jugar hoy?',
                                      style: TextStyle(color: Colors.white70, fontSize: constraints.maxWidth * 0.04)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: headerHeight * 0.04),
                        // Tu input PIN y botón
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: screenSize.height * 0.03),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: pinController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Ingresa PIN de juego',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                    contentPadding:
                                      EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.015),
                                ),
                              ),
                                  SizedBox(height: screenSize.height * 0.015),
                              ElevatedButton(
                                onPressed: () {
                                  final pin = pinController.text.trim();
                                  if (pin.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Por favor ingresa un PIN valido para poder jugar'),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushNamed(context, '/joinLobby',
                                        arguments: pin);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade400,
                                  minimumSize: Size(double.infinity, max(48.0, screenSize.height * 0.06)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  elevation: 6,
                                  shadowColor: Colors.amber.shade300,
                                ),
                                child: Text(
                                  'Unirse al juego',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: constraints.maxWidth * 0.04,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                      ],
                    ),
                  ),
                ),
              ),

              // Tus Quizzes header (non-scrolling content)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.01),
                sliver: SliverToBoxAdapter(
                  child: Builder(builder: (ctx) {
                    final userQuizzes = quizBloc.userQuizzes ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tus Quizzes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: constraints.maxWidth * 0.045)),
                        SizedBox(height: 8),
                        if (_loadingUserQuizzes) Center(child: CircularProgressIndicator()),
                        if (!_loadingUserQuizzes && userQuizzes.isEmpty)
                          Text('No tienes quizzes aún. Crea uno con el botón +', style: TextStyle(color: Colors.grey[700])),
                      ],
                    );
                  }),
                ),
              ),

              // Tus Quizzes grid (as a sliver so following sections remain visible)
              Builder(builder: (ctx) {
                final userQuizzes = quizBloc.userQuizzes ?? [];
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.01),
                  sliver: staggered.SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: max(8.0, screenSize.height * 0.01),
                    crossAxisSpacing: constraints.maxWidth * 0.02,
                    childCount: userQuizzes.length,
                    itemBuilder: (context, index) {
                            final q = userQuizzes[index];
                            // If coverImageUrl looks like a media id (not a full http url), trigger fetch
                            String? coverId = q.coverImageUrl;
                            Uint8List? cachedBytes;
                            String? cachedUrlOverride;
                            if (coverId != null && !coverId.startsWith('http')) {
                              cachedBytes = _coverCache[coverId];
                              cachedUrlOverride = _coverUrlCache[coverId];
                              if (!_fetchingCover.contains(coverId) && cachedBytes == null && cachedUrlOverride == null) {
                                _fetchingCover.add(coverId);
                                // fetch asynchronously and setState when ready
                                _fetchCoverIfNeeded(coverId);
                              }
                            }

                            return GestureDetector(
                              onLongPress: () async {
                                if (coverId != null && !coverId.startsWith('http')) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reintentando obtener portada...')));
                                  if (!_fetchingCover.contains(coverId)) {
                                    _fetchingCover.add(coverId);
                                    await _fetchCoverIfNeeded(coverId);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No hay una portada en formato media-id para reintentar')));
                                }
                              },
                              child: KahootCard(
                                kahoot: q,
                                coverBytes: cachedBytes,
                                coverUrlOverride: cachedUrlOverride,
                                onTap: () => _showQuizOptions(context, q),
                                isLocalCopy: q.isLocal,
                              ),
                            );
                    },
                  ),
                );
              }),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recientes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: constraints.maxWidth * 0.045
                          )),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Ver todo',
                          style: TextStyle(
                              color: AppColor.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final kahoot = recentKahoots[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
                        padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: screenSize.height * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: AppColor.primary, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kahoot.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: constraints.maxWidth * 0.04
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Hace 2 días • 80% correcto',
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.03,
                                  color: Colors.grey[700]
                                )),
                          ],
                        ),
                      );
                    },
                    childCount: recentKahoots.length,
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.0125),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recomendado para ti',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: constraints.maxWidth * 0.045
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.0125),
                sliver: staggered.SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: max(8.0, screenSize.height * 0.01),
                  crossAxisSpacing: constraints.maxWidth * 0.02,
                  childCount: recommendedKahoots.length,
                  itemBuilder: (context, index) {
                    final kahoot = recommendedKahoots[index];
                    return KahootCard(
                      kahoot: kahoot,
                        onTap: () => Navigator.pushNamed(context, '/gameDetail',
                          arguments: kahoot.quizId),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: min(screenSize.height * 0.06, 120))),
            ],
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        // Ensure the editor starts fresh: clear any previous currentQuiz
        final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
        quizBloc.clear();
        // Abrir selector de plantillas; si el usuario elige una, navegar al editor con la plantilla
        final selected = await Navigator.pushNamed(context, '/templateSelector');
        if (selected != null && selected is Quiz) {
          Navigator.pushNamed(context, '/create', arguments: selected);
        } else {
          // Explicitly request a cleared editor when creating a new quiz
          Navigator.pushNamed(context, '/create', arguments: {'clear': true});
        }
      },
      backgroundColor: Colors.amber.shade400,
      child: Icon(Icons.add),
      elevation: 6,
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: _builBottonNav(context, 0),
  );
  }

  Widget _builBottonNav(BuildContext context, int currentIndex){
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index){
        switch(index){
          case 0:
            Navigator.pushReplacementNamed(context, '/dashboard');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/discover');
            break;
          case 2:
            //El espcio entre botones centrales (FAB) no hace nada
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/library');
            break;
          case 4: 
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColor.primary,
      unselectedItemColor: Colors.grey,
      items: const[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Descubre'),
        BottomNavigationBarItem(icon: Icon(null), label: ''), //Espacio para FAB
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Biblioteca'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
