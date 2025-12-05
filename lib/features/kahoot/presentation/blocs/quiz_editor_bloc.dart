import 'package:flutter/material.dart';

import '../../domain/entities/Quiz.dart';
import '../../domain/entities/Question.dart';
import '../../domain/repositories/QuizRepository.dart';
import '../../application/dtos/create_quiz_dto.dart';
import '../../application/create_quiz_usecase.dart';
import '../../application/get_quiz_usecase.dart';
import '../../application/update_quiz_usecase.dart';
import '../../application/delete_quiz_usecase.dart';
import '../../application/list_user_quizzes_usecase.dart';

/// BLoC para gestionar el editor de Quiz.
/// - Inyecta un `QuizRepository` para persistencia.
/// - Usa los UseCases existentes (`run(...)`).
class QuizEditorBloc extends ChangeNotifier {
  final QuizRepository repository;

  Quiz? currentQuiz; // Quiz en edición
  bool isLoading = false;
  String? errorMessage;
  List<Quiz>? userQuizzes;

  QuizEditorBloc(this.repository);

  // Crear un quiz a partir de un DTO
  Future<void> createQuiz(CreateQuizDto dto) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prevTemplate = currentQuiz?.templateId;
      final useCase = CreateQuizUsecase(repository);
      final created = await useCase.run(dto);
      // preserva la asociación de plantilla del lado del cliente si está presente
      if (prevTemplate != null) created.templateId = prevTemplate;
      currentQuiz = created;
      // Aseguro que el quiz recién creado/devuelto se refleje en la
      // lista de quizzes del usuario para que el dashboard (portada) muestre los cambios.
      _upsertIntoUserQuizzes(created);
    } catch (e) {
      errorMessage = 'Error al crear el Quiz: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Cargar quiz por id
  Future<void> loadQuiz(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final useCase = GetKahootUseCase(repository);
      final quiz = await useCase.run(id);
      currentQuiz = quiz;
    } catch (e) {
      errorMessage = 'Error al cargar el Quiz: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Actualiza un quiz existente con un DTO (reemplaza preguntas/metadata)
  Future<void> updateQuiz(String quizId, CreateQuizDto dto) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prevTemplate = currentQuiz?.templateId;
      final useCase = UpdateKahootUseCase(repository);
      final updated = await useCase.run(quizId, dto);
      if (prevTemplate != null) updated.templateId = prevTemplate;
      currentQuiz = updated;
      // Mantiene la lista de quizzes del usuario sincronizada para que el dashboard refleje los cambios de inmediato
      _upsertIntoUserQuizzes(updated);
    } catch (e) {
      errorMessage = 'Error al actualizar el Quiz: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Elimina un quiz
  Future<void> deleteQuiz(String quizId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final useCase = DeleteKahootUseCase(repository);
      await useCase.run(quizId);
      // Si el quiz eliminado era el current, limpiamos
      if (currentQuiz?.quizId == quizId) currentQuiz = null;
    } catch (e) {
      errorMessage = 'Error al eliminar el Quiz: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Lista quizzes de un autor
  Future<void> loadUserQuizzes(String authorId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final useCase = ListUserKahootsUseCase(repository);
      final fetched = await useCase.run(authorId);

      // Fusiona los quizzes obtenidos del servidor con la lista local existente para evitar
      // perder elementos que puedan existir solo en el cliente o que no sean devueltos
      // por el backend en cada respuesta. Estrategia de coincidencia:
      // - Si ambos tienen un quizId no vacío, se emparejan por quizId y se prefiere la versión del servidor.
      // - Para ids vacíos (elementos locales), se emparejan por la firma de título+createdAt.
      userQuizzes ??= [];

      // Construye mapas para búsqueda rápida
      final existingById = <String, Quiz>{};
      final existingBySig = <String, Quiz>{};
      for (final q in userQuizzes!) {
        if (q.quizId.isNotEmpty) existingById[q.quizId] = q;
        final sig = '${q.title.trim()}|${q.createdAt.toIso8601String()}|${q.coverImageUrl ?? ''}';
        existingBySig[sig] = q;
      }

      // Comienza con la lista del servidor, pero asegúrate de preservar los elementos que existen solo localmente
      final merged = <Quiz>[];
      for (final s in fetched) {
        if (s.quizId.isNotEmpty && existingById.containsKey(s.quizId)) {
            // preferimos la versión del servidor pero mantenemos la referencia local mínima
          merged.add(s);
          existingById.remove(s.quizId);
        } else {
          final sig = '${s.title.trim()}|${s.createdAt.toIso8601String()}|${s.coverImageUrl ?? ''}';
          if (existingBySig.containsKey(sig)) {
            // el servidor devolvió un elemento que coincide con una firma local — se prefiere la versión del servidor
            merged.add(s);
            existingBySig.remove(sig);
          } else {
            // nuevo elemento recibido del servidor
            merged.add(s);
          }
        }
      }

      // Agrega cualquier elemento restante que exista solo localmente y que el servidor no devolvió
      for (final leftover in existingById.values) {
        merged.insert(0, leftover);
      }
      for (final leftover in existingBySig.values) {
        merged.insert(0, leftover);
      }

      // Elimina duplicados de la lista fusionada: se prefiere el `quizId` único cuando está presente,
      // de lo contrario, se utiliza una firma basada en título+createdAt+cover para identificar elementos locales.
      final seenIds = <String>{};
      final seenSigs = <String>{};
      final deduped = <Quiz>[];
      for (final q in merged) {
        final id = q.quizId;
        final sig = '${q.title.trim()}|${q.createdAt.toIso8601String()}|${q.coverImageUrl ?? ''}';
        if (id.isNotEmpty) {
          if (seenIds.contains(id)) continue;
          seenIds.add(id);
          deduped.add(q);
        } else {
          if (seenSigs.contains(sig)) continue;
          seenSigs.add(sig);
          deduped.add(q);
        }
      }

      userQuizzes = deduped;
    } catch (e) {
      errorMessage = 'Error al listar quizzes: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Utilities
  void clear() {
    currentQuiz = null;
    errorMessage = null;
    notifyListeners();
  }

  /// Establece el quiz actual y notifica a los oyentes.
  void setCurrentQuiz(Quiz quiz) {
    currentQuiz = quiz;
    notifyListeners();
  }

  // Helpers de edición local utilizados por la UI para modificar el quiz en memoria y notificar a los oyentes
  void updateQuestionAt(int index, Question updated) {
    if (currentQuiz == null) return;
    if (index < 0 || index >= currentQuiz!.questions.length) return;
    currentQuiz!.questions[index] = updated;
    notifyListeners();
  }

  void insertQuestionAt(int index, Question question) {
    if (currentQuiz == null) return;
    final insertIdx = index.clamp(0, currentQuiz!.questions.length);
    currentQuiz!.questions.insert(insertIdx, question);
    notifyListeners();
  }

  void removeQuestionAt(int index) {
    if (currentQuiz == null) return;
    if (index < 0 || index >= currentQuiz!.questions.length) return;
    currentQuiz!.questions.removeAt(index);
    notifyListeners();
  }

  /// Persiste el `currentQuiz` actual enviándolo al repositorio.
  /// Retorna la entidad guardada y actualiza `currentQuiz` con la respuesta del servidor.
  Future<void> saveCurrentQuiz() async {
    if (currentQuiz == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prevTemplate = currentQuiz!.templateId;
      final saved = await repository.save(currentQuiz!);
      if (prevTemplate != null) saved.templateId = prevTemplate;
      currentQuiz = saved;
      // Actualiza o inserta en la caché de userQuizzes para que las listas de la UI reflejen el estado guardado
      _upsertIntoUserQuizzes(saved);
    } catch (e) {
      errorMessage = 'Error al persistir el quiz: $e';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Ayudante de upsert: inserta o reemplaza el quiz en `userQuizzes` para que
  // las vistas de la UI (dashboard/portada) reflejen inmediatamente los cambios realizados en el editor.
  void _upsertIntoUserQuizzes(Quiz q) {
    userQuizzes ??= [];

    // Preferir coincidencia por quizId no vacío
    if (q.quizId.isNotEmpty) {
      final idx = userQuizzes!.indexWhere((x) => x.quizId.isNotEmpty && x.quizId == q.quizId);
      if (idx != -1) {
        userQuizzes![idx] = q;
        return;
      }
    }

    // Alternativa: buscar coincidencia por firma (título + createdAt + portada) para elementos locales
    final sig = '${q.title.trim()}|${q.createdAt.toIso8601String()}|${q.coverImageUrl ?? ''}';
    final idxSig = userQuizzes!.indexWhere((x) {
      final xsig = '${x.title.trim()}|${x.createdAt.toIso8601String()}|${x.coverImageUrl ?? ''}';
      return xsig == sig;
    });
    if (idxSig != -1) {
      userQuizzes![idxSig] = q;
      return;
    }

    // Si no se encontró coincidencia, inserta al inicio para que el quiz actualizado/creado sea visible
    userQuizzes!.insert(0, q);
  }
}