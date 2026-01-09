import 'dart:math';
import 'dart:typed_data';

import 'package:Trivvy/features/challenge/application/use_cases/single_player_usecases.dart';
import 'package:Trivvy/features/challenge/presentation/pages/single_player_challenge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'
    as staggered;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../features/Administrador/Presentacion/pages/Persona_Page.dart';
import '../features/discovery/presentation/pages/discover_page.dart';
import '/features/gameSession/presentation/pages/join_game.dart';
import '../common_widgets/kahoot_card.dart';
import '../common_widgets/main_bottom_nav_bar.dart';
import '../core/constants/colors.dart';
import '../features/kahoot/application/dtos/create_quiz_dto.dart';
import '../features/kahoot/domain/entities/Quiz.dart';
import '../features/kahoot/presentation/blocs/quiz_editor_bloc.dart';
import '../features/media/presentation/blocs/media_editor_bloc.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/user/presentation/pages/profile_page.dart';
import '../features/user/presentation/blocs/auth_bloc.dart';
import '../features/library/presentation/providers/library_provider.dart';

import 'package:Trivvy/features/subscriptions/presentation/utils/subscription_guard.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  bool _loadingUserQuizzes = false;
  final Map<String, Uint8List?> _coverCache = {};
  final Map<String, String?> _coverUrlCache = {};
  final Set<String> _fetchingCover = {};

  // Firmas (identificadores ligeros) de los quizzes que ya se insertaron desde
  // los argumentos de navegación durante esta sesión. Se usan para evitar insertar
  // duplicados cuando se navega repetidamente.
  final Set<String> _insertedQuizSignatures = {};
  String _quizCacheKey(String quizId) => '__quiz__${quizId}';

  @override
  void initState() {
    super.initState();
    // Se cargan los quizzes del usuario al ingresar (usa un ID de autor de marcador de posición)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
      if (quizBloc.userQuizzes == null) {
        // Se intenta cargar los quizzes del usuario. Si no hay un authorId en currentQuiz,
        // utiliza un authorId de prueba por defecto para que el Dashboard muestre
        // los quizzes creados durante el desarrollo o pruebas.
        final auth = Provider.of<AuthBloc>(context, listen: false);
        const defaultTestAuthorId = 'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
        var authorIdCandidate =
            auth.currentUser?.id ?? quizBloc.currentQuiz?.authorId ?? '';
        if (authorIdCandidate.isEmpty) authorIdCandidate = defaultTestAuthorId;

        setState(() => _loadingUserQuizzes = true);
        try {
          await quizBloc.loadUserQuizzes(authorIdCandidate);
        } catch (e) {
          // Registrar el error pero no bloqueaa la interfaz si el backend rechaza el authorId.
          print(
            '[dashboard] loadUserQuizzes error for author=$authorIdCandidate -> $e',
          );
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
      print(
        '[dashboard] getMedia for $mediaId -> path=$mediaPath fileLen=${response.file?.length ?? 0}',
      );

      if (response.file != null && response.file!.isNotEmpty) {
        _coverCache[mediaId] = response.file;
        print(
          '[dashboard] cached bytes for $mediaId (len=${response.file!.length})',
        );
      } else if (mediaPath is String && mediaPath.startsWith('http')) {
        _coverUrlCache[mediaId] = mediaPath;
        print('[dashboard] cached url for $mediaId -> $mediaPath');
      } else if (mediaPath is String && mediaPath.isNotEmpty) {
        // Prueba los siguientes URLs candidatas construidas a partir de los baseUrl obtenidos de los providers (mediaRepo/storageRepo)
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
          candidates.add(
            '$baseUrl/storage/file/${Uri.encodeComponent(mediaPath)}',
          );
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

        if (!_coverCache.containsKey(mediaId) &&
            !_coverUrlCache.containsKey(mediaId)) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Eliminar Quiz'),
          content: Text(
            '¿Estás seguro que deseas eliminar "${q.title}" de forma permanente?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Solo llama al delete en el backend si el quiz no está marcado como local.
        // El frontend no debe inferir semánticas del backend a partir del formato del UUID — usa la bandera explícita `isLocal`.
        if (q.isLocal) {
          // Quiz solo local — eliminar únicamente de la lista local sin llamar a la API.
          // NO eliminar solo por `quizId == ''` porque muchos elementos locales
          // pueden tener ids vacíos; prefiera la identidad del objeto y, si no,
          // use título + createdAt como heurística de respaldo.
          if (quizBloc.userQuizzes != null) {
            quizBloc.userQuizzes!.removeWhere((item) {
              if (identical(item, q)) return true;
              // Si no son el mismo objeto, se comprobará más abajo por ID:
              // solo se considera coincidencia cuando ambos quizId no están vacíos.
              if (item.quizId.isNotEmpty &&
                  q.quizId.isNotEmpty &&
                  item.quizId == q.quizId)
                return true;
              // Si ambos quizId están vacíos, emplear una heurística más robusta:
              // coincidir por título + createdAt (timestamp) para identificar duplicados.
              if (item.quizId.isEmpty &&
                  q.quizId.isEmpty &&
                  item.title == q.title &&
                  item.createdAt.toIso8601String() ==
                      q.createdAt.toIso8601String())
                return true;
              return false;
            });
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Quiz eliminado localmente')));
          if (mounted) setState(() {});
          return;
        }

        print('[dashboard] requesting delete for quizId=${q.quizId}');
        await quizBloc.deleteQuiz(q);
        if (quizBloc.errorMessage != null) {
          print('[dashboard] delete returned error: ${quizBloc.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${quizBloc.errorMessage}'),
            ),
          );
          return;
        }
        // Elimina de la lista local si está presente (no confiar solo en el quizId; usar mismas heurísticas que más abajo)
        if (quizBloc.userQuizzes != null) {
          quizBloc.userQuizzes!.removeWhere((item) {
            if (item.quizId.isNotEmpty &&
                q.quizId.isNotEmpty &&
                item.quizId == q.quizId)
              return true;
            if (identical(item, q)) return true;
            if (item.quizId.isEmpty &&
                q.quizId.isEmpty &&
                item.title == q.title &&
                item.createdAt.toIso8601String() ==
                    q.createdAt.toIso8601String())
              return true;
            return false;
          });
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Quiz eliminado')));
        if (mounted) setState(() {});
      } catch (e) {
        print('[dashboard] Exception during delete flow: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _showQuizOptions(BuildContext context, Quiz q) async {
    final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
    final quizKey = _quizCacheKey(q.quizId);
    final mediaKey = q.coverImageUrl;
    Uint8List? bytes = mediaKey != null && !mediaKey.startsWith('http')
        ? _coverCache[mediaKey]
        : null;
    bytes ??= _coverCache[quizKey];
    String? url = mediaKey != null
        ? (_coverUrlCache[mediaKey] ??
              (mediaKey.startsWith('http') ? mediaKey : null))
        : _coverUrlCache[quizKey];

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
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover)
                            : (url != null
                                  ? Image.network(url, fit: BoxFit.cover)
                                  : (q.coverImageUrl != null &&
                                            q.coverImageUrl!.startsWith('http')
                                        ? Image.network(
                                            q.coverImageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Center(child: Icon(Icons.image)))),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    q.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    // Cierra primero el bottom sheet para evitar que las notificaciones del Bloc
                                    // provoquen errores tipo "notifyListeners durante build" o actualizaciones inoportunas.
                                    Navigator.of(ctx).pop();
                                    try {
                                      if (q.quizId.isNotEmpty && !q.isLocal) {
                                        // Pre-cargar el quiz seleccionado en el bloc para que la UI muestre ese mismo quiz mientras llega el fetch
                                        quizBloc.setCurrentQuiz(q);
                                        // Carga el quiz completo en el Bloc (actualiza currentQuiz antes de navegar al editor)
                                        await quizBloc.loadQuiz(q.quizId);
                                      } else {
                                        // Para elementos locales o sin ID: uso el objeto recibido tal cual;
                                        // programar setCurrentQuiz después del frame para evitar notifyListeners durante build
                                        WidgetsBinding.instance
                                            .addPostFrameCallback(
                                              (_) => quizBloc.setCurrentQuiz(q),
                                            );
                                      }
                                      Navigator.pushNamed(context, '/create');
                                    } catch (e) {
                                      print(
                                        '[dashboard] failed to load quiz for edit id=${q.quizId} -> $e',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error cargando el quiz para edición: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              q.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ID: ${q.quizId.isNotEmpty ? q.quizId : '(sin id)'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            // Template / Theme info
                            Text(
                              'Tema: ${_themeName(q.themeId)}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            if (q.templateId != null) SizedBox(height: 4),
                            if (q.templateId != null)
                              Text(
                                'Plantilla: ${q.templateId}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Fila de botones.
                  Row(
                    children: [
                      // Editar: principal
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Cierra primero el bottom sheet para evitar notifyDuringBuild
                              Navigator.of(ctx).pop();
                              try {
                                if (q.quizId.isNotEmpty && !q.isLocal) {
                                  // Pre-cargar el quiz seleccionado en el bloc para que la UI muestre ese mismo quiz mientras llega el fetch
                                  quizBloc.setCurrentQuiz(q);
                                  await quizBloc.loadQuiz(q.quizId);
                                } else {
                                  WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => quizBloc.setCurrentQuiz(q),
                                  );
                                }
                                Navigator.pushNamed(context, '/create');
                              } catch (e) {
                                print(
                                  '[dashboard] failed to load quiz for edit (button) id=${q.quizId} -> $e',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error cargando el quiz para edición: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.edit, size: 20),
                            label: Text(
                              'Editar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                            // Realizar una petición POST para crear la copia del quiz en el backend (se construye el DTO a continuación)
                            Navigator.of(ctx).pop();

                            final auth = Provider.of<AuthBloc>(
                              context,
                              listen: false,
                            );
                            const defaultTestAuthorId =
                                'f1986c62-7dc1-47c5-9a1f-03d34043e8f4';
                            final authorIdCandidate =
                                (auth.currentUser?.id ?? '').isNotEmpty
                                ? auth.currentUser!.id
                                : ((q.authorId.isEmpty ||
                                          q.authorId.contains('placeholder'))
                                      ? defaultTestAuthorId
                                      : q.authorId);

                            // Mapear preguntas y respuestas a los DTOs Create* para la petición de duplicado.
                            // NO se generan ni se reasignan IDs aquí: el backend debe asignar los nuevos identificadores.
                            // Se copian los campos relevantes (texto, media, tipo, tiempo, puntos) y se mapean
                            // las respuestas preservando texto, media y la marca de correcta.
                            final mappedQuestions = q.questions.map((origQ) {
                              final answers = origQ.answers
                                  .map(
                                    (a) => CreateAnswerDto(
                                      answerText: a.text,
                                      answerImage: a.mediaUrl,
                                      isCorrect: a.isCorrect,
                                    ),
                                  )
                                  .toList();
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al duplicar: ${quizBloc.errorMessage}',
                                    ),
                                  ),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Quiz duplicado y creado'),
                                ),
                              );
                              if (mounted) setState(() {});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al duplicar: $e'),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy, size: 18),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Dup',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Eliminar: botón compacto
                      SizedBox(
                        width: 96,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _confirmAndDelete(context, q);
                          },
                          icon: Icon(Icons.delete, size: 18),
                          label: Text(
                            'Eliminar',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
      },
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

  final List<Map<String, dynamic>> activeTrivvys = [
    {
      'id': 'mock_quiz_1',
      'title': 'Ciencia y Matemática Básica',
      'questions': 5,
    },
    {
      'id': 'mock_quiz_ddd',
      'title': 'Domain-Driven Design Básico',
      'questions': 5,
    },
  ];

  Future<void> _startTrivvy(
    BuildContext context,
    Map<String, dynamic> quiz,
  ) async {
    final startAttempt = Provider.of<StartAttemptUseCase>(
      context,
      listen: false,
    );
    try {
      final res = await startAttempt.execute(
        kahootId: quiz['id'] as String,
        playerId: 'Jugador',
        totalQuestions: quiz['questions'] as int,
      );
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SinglePlayerChallengeScreen(
            nickname: res.game.playerId,
            quizId: res.game.quizId,
            totalQuestions: res.game.totalQuestions,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SinglePlayerChallengeScreen(
            nickname: 'Jugador',
            quizId: quiz['id'] as String,
            totalQuestions: quiz['questions'] as int,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el bloc si es necesario en el futuro
    final quizBloc = Provider.of<QuizEditorBloc>(context);
    final auth = Provider.of<AuthBloc>(context, listen: true);
    final user = auth.currentUser;
    final displayName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()
        : (user?.userName ?? 'Jugador');
    // Si el navegador pasó un cuestionario creado como argumento, se inserta en userQuizzes
    //para que sea visible inmediatamente sin llamar al backend.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Quiz) {
      quizBloc.userQuizzes ??= [];
      final incoming = args;
      print(
        '[dashboard] nav arg received: quizId=${incoming.quizId} title=${incoming.title} isLocal=${incoming.isLocal}',
      );
      // Build a lightweight signature to detect repeated navigation inserts.
      final sigParts = [
        incoming.title.trim(),
        incoming.createdAt.toIso8601String(),
        incoming.coverImageUrl ?? '',
      ];
      final signature = sigParts.join('|');
      print('[dashboard] received nav arg quiz signature=$signature');

      if (_insertedQuizSignatures.contains(signature)) {
        print('[dashboard] skipping insert: signature already seen');
      } else {
        Quiz toInsert = incoming;
        // NO marca un quiz entrante como copia local solo porque su id esté vacío:
        // lo trato como local únicamente si incoming.isLocal == true. Esto asegura que
        // los quizzes recién creados que vuelven vía navegación se muestren como items normales.
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

        // Insertar siempre una instancia nueva en la lista del usuario
        // para evitar mutaciones accidentales por referencias compartidas.
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

        final exists = quizBloc.userQuizzes!.any(
          (q) => q.quizId == candidate.quizId && q.title == candidate.title,
        );
        if (!exists) {
          quizBloc.userQuizzes!.insert(0, candidate);
          _insertedQuizSignatures.add(signature);
          print(
            '[dashboard] inserted quiz from nav args: id=${candidate.quizId} title=${candidate.title}',
          );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        // Limitar la altura del header para evitar tamaños enormes al hacer overscroll
        double headerHeight = min(
          constraints.maxHeight * 0.45,
          screenSize.height * 0.45,
        );
        // Asegurar un mínimo para que el header no colapse en pantallas pequeñas
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
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: headerHeight * 0.06),
                      // Colocar el logo arriba del saludo y alineado a la izquierda
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: (constraints.maxWidth * 0.12).clamp(
                              40.0,
                              80.0,
                            ),
                            height: (constraints.maxWidth * 0.12).clamp(
                              40.0,
                              80.0,
                            ),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => Container(
                              width: (constraints.maxWidth * 0.12).clamp(
                                40.0,
                                80.0,
                              ),
                              height: (constraints.maxWidth * 0.12).clamp(
                                40.0,
                                80.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          SizedBox(width: constraints.maxWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Hola, $displayName!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: constraints.maxWidth * 0.07,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Listo para jugar hoy?',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: constraints.maxWidth * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: headerHeight * 0.04),
                      // Tarjeta con CTA para ingresar al juego mediante PIN (abre el modal actualizado)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04,
                          vertical: min(
                            screenSize.height * 0.03,
                            headerHeight * 0.22,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      DraggableScrollableSheet(
                                        expand: false,
                                        initialChildSize: 0.6,
                                        minChildSize: 0.35,
                                        maxChildSize: 0.95,
                                        builder: (context, scrollController) {
                                          return JoinGameScreen(
                                            scrollController: scrollController,
                                          );
                                        },
                                      ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade400,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
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
            // Tus Quizzes header
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: screenSize.height * 0.01,
              ),
              sliver: SliverToBoxAdapter(
                child: Builder(
                  builder: (ctx) {
                    final userQuizzes = quizBloc.userQuizzes ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus Quizzes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: constraints.maxWidth * 0.045,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (_loadingUserQuizzes)
                          Center(child: CircularProgressIndicator()),
                        if (!_loadingUserQuizzes && userQuizzes.isEmpty)
                          Text(
                            'No tienes quizzes aún. Crea uno con el botón +',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Tus Quizzes grid
            Builder(
              builder: (ctx) {
                final userQuizzes = quizBloc.userQuizzes ?? [];
                return SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.05,
                    vertical: screenSize.height * 0.01,
                  ),
                  sliver: staggered.SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: max(8.0, screenSize.height * 0.01),
                    crossAxisSpacing: constraints.maxWidth * 0.02,
                    childCount: userQuizzes.length,
                    itemBuilder: (context, index) {
                      final q = userQuizzes[index];
                      // Si coverImageUrl parece un id de media (no una url http completa), desencadena la obtención
                      String? coverId = q.coverImageUrl;
                      Uint8List? cachedBytes;
                      String? cachedUrlOverride;
                      if (coverId != null && !coverId.startsWith('http')) {
                        cachedBytes = _coverCache[coverId];
                        cachedUrlOverride = _coverUrlCache[coverId];
                        if (!_fetchingCover.contains(coverId) &&
                            cachedBytes == null &&
                            cachedUrlOverride == null) {
                          _fetchingCover.add(coverId);
                          // Lanzar la obtención en segundo plano y actualizar el estado cuando termine.
                          // No espero aquí (estamos en el builder); _fetchingCover evita solicitudes duplicadas.
                          _fetchCoverIfNeeded(coverId);
                        }
                      }

                      final auth = Provider.of<AuthBloc>(
                        context,
                        listen: false,
                      );
                      final authorName =
                          (auth.currentUser?.id == q.authorId &&
                              (auth.currentUser?.name.isNotEmpty ?? false))
                          ? auth.currentUser!.name
                          : q.authorId;

                      return GestureDetector(
                        onLongPress: () async {
                          if (coverId != null && !coverId.startsWith('http')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reintentando obtener portada...',
                                ),
                              ),
                            );
                            if (!_fetchingCover.contains(coverId)) {
                              _fetchingCover.add(coverId);
                              await _fetchCoverIfNeeded(coverId);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No hay una portada en formato media-id para reintentar',
                                ),
                              ),
                            );
                          }
                        },
                        child: KahootCard(
                          kahoot: q,
                          authorNameOverride: authorName,
                          coverBytes: cachedBytes,
                          coverUrlOverride: cachedUrlOverride,
                          onTap: () => _showQuizOptions(context, q),
                          isLocalCopy: q.isLocal,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: 0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recientes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth * 0.045,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Ver todo',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final kahoot = recentKahoots[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.04,
                      vertical: screenSize.height * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(color: AppColor.primary, width: 4),
                      ),
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
                            fontSize: constraints.maxWidth * 0.04,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hace 2 días • 80% correcto',
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.03,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: recentKahoots.length),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: screenSize.height * 0.0125,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Recomendado para ti',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: constraints.maxWidth * 0.045,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: screenSize.height * 0.0125,
              ),
              sliver: staggered.SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: max(8.0, screenSize.height * 0.01),
                crossAxisSpacing: constraints.maxWidth * 0.02,
                childCount: recommendedKahoots.length,
                itemBuilder: (context, index) {
                  final kahoot = recommendedKahoots[index];
                  final auth = Provider.of<AuthBloc>(context, listen: false);
                  final authorName =
                      (auth.currentUser?.id == kahoot.authorId &&
                          (auth.currentUser?.name.isNotEmpty ?? false))
                      ? auth.currentUser!.name
                      : kahoot.authorId;
                  return KahootCard(
                    kahoot: kahoot,
                    authorNameOverride: authorName,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/gameDetail',
                      arguments: kahoot.quizId,
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              // Sección Trivvys activos
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: screenSize.height * 0.025,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trivvys Activos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth * 0.045,
                      ),
                    ),
                    Text(
                      '${activeTrivvys.length} juegos',
                      style: TextStyle(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: constraints.maxWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              // Lista de trivvys activos
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: screenSize.height * 0.005,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final quiz = activeTrivvys[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _startTrivvy(context, quiz),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.045,
                            vertical: screenSize.height * 0.018,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: constraints.maxWidth * 0.042,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${quiz['questions']} preguntas',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: constraints.maxWidth * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.play_circle_fill,
                                color: AppColor.primary,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: activeTrivvys.length),
              ),
            ),
            // Espacio inferior para dejar respirar el FAB
            SliverToBoxAdapter(
              child: SizedBox(height: min(screenSize.height * 0.06, 120)),
            ),
          ],
        );
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  List<Widget> _buildPages(BuildContext context) {
    final auth = Provider.of<AuthBloc>(context, listen: true);
    final currentUser = auth.currentUser;
    return [
      const HomePageContent(), // 0: Inicio
      const DiscoverScreen(), // 1: Descubre (Placeholder)
      const SizedBox.shrink(), // 2: Placeholder for FAB
      const LibraryPage(), // 3: Biblioteca
      currentUser == null
          ? const Scaffold(
              body: Center(child: Text('Inicia sesión para ver tu perfil')),
            )
          : ProfilePage(user: currentUser), // 4: Perfil
    ];
  }

  /*
=======
  final List<Widget> _pages = const [
    HomePageContent(), // 0: Inicio
    DiscoverScreen(), //Discovery
    SizedBox.shrink(), // 2: Placeholder for FAB
    LibraryPage(), // 3: Biblioteca (Épica 7)
    PersonaPage(), // 4: Perfil (Placeholder)
  ];
>>>>>>> epica9y11
*/
  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/create');
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay usuario (tras logout), redirige inmediatamente a la pantalla de bienvenida
    final auth = Provider.of<AuthBloc>(context, listen: true);
    if (auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
      });
      // Devuelve un contenedor vacío mientras se realiza la navegación
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: AppColor.background,
      body: IndexedStack(index: _currentIndex, children: _buildPages(context)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Obtenemos el LibraryProvider (listen: false porque estamos en una función)
          final libraryProvider = Provider.of<LibraryProvider>(
            context,
            listen: false,
          );

          // Obtenemos el total de Kahoots creados
          final totalCreados = libraryProvider.createdKahoots.length;

          // Aplicamos el Guard: Si devuelve 'false', el Guard ya mostró el diálogo y cortamos aquí.
          if (!SubscriptionGuard.checkLimit(
            context,
            currentCount: totalCreados,
            maxFree: 5,
            itemName: 'Kahoots',
          )) {
            return; // Detenemos la ejecución
          }
          // Aseguro de que el editor comience vacío: limpiar cualquier currentQuiz previo
          final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
          quizBloc.clear();
          // Abrir selector de plantillas; si el usuario elige una, navegar al editor con la plantilla
          final selected = await Navigator.pushNamed(
            context,
            '/templateSelector',
          );
          if (selected != null && selected is Quiz) {
            Navigator.pushNamed(context, '/create', arguments: selected);
          } else {
            // Solicita explícitamente un editor limpio al crear un nuevo quiz
            Navigator.pushNamed(context, '/create', arguments: {'clear': true});
          }
        },
        backgroundColor: Colors.amber.shade400,
        child: Icon(Icons.add),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
