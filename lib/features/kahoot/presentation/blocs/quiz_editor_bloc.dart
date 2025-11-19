import 'package:flutter/material.dart';

import '../../domain/entities/Quiz.dart';
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
      final useCase = CreateQuizUsecase(repository);
      final created = await useCase.run(dto);
      currentQuiz = created;
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
      final useCase = UpdateKahootUseCase(repository);
      final updated = await useCase.run(quizId, dto);
      currentQuiz = updated;
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
      userQuizzes = await useCase.run(authorId);
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
}