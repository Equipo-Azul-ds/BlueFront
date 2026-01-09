import 'package:flutter/material.dart';
import '../../../../features/discovery/domain/entities/kahoot.dart';
import '../../../../features/discovery/domain/entities/theme.dart';
import '../../../../features/discovery/domain/Repositories/IDiscoverRepository.dart';
import '../../../../features/discovery/domain/Repositories/IThemeRepositorie.dart';
import '../../../../features/Notifications/Dominio/Repositorios/INotificationRepository.dart';
import '../../../../features/Administrador/Dominio/Repositorio/IUserManagementRepository.dart';
import '../../../../features/Administrador/Aplication/dtos/user_query_params.dart';

class DashboardProvider extends ChangeNotifier {
  final IDiscoverRepository quizRepository;
  final IThemeRepository themeRepository;
  final INotificationRepository notificationRepository;
  final IUserRepository userRepository;

  bool _isLoading = false;
  int _totalQuizzes = 0;
  int _newKahootsCount = 0;
  int _totalUsers = 0;
  int _newUsersCount = 0;
  int _totalCategories = 0;
  Map<String, int> _categoryPopularity = {};

  DashboardProvider({
    required this.quizRepository,
    required this.themeRepository,
    required this.notificationRepository,
    required this.userRepository,
  });

  // Getters
  bool get isLoading => _isLoading;
  int get totalQuizzes => _totalQuizzes;
  int get newKahootsCount => _newKahootsCount;
  int get totalUsers => _totalUsers;
  int get newUsersCount => _newUsersCount;
  int get totalCategories => _totalCategories;
  Map<String, int> get categoryPopularity => _categoryPopularity;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      // Obtener usuarios
      final usersResult = await userRepository.getUsers(const UserQueryParams(limit: 100));

      usersResult.fold(
            (failure) => print("Error en dashboard usuarios: $failure"),
            (paginatedList) {
          _totalUsers = paginatedList.totalCount;
          _newUsersCount = paginatedList.users.where((u) =>
          now.difference(u.createdAt).inDays <= 7).length;
        },
      );

      // Obtener Categorías
      final themesResult = await themeRepository.getThemes();
      List<ThemeVO> themes = [];
      themesResult.fold(
            (failure) => print("Error al obtener temas: $failure"),
            (themeList) {
          themes = themeList;
          _totalCategories = themeList.length;
        },
      );

      //  Obtener Kahoots y procesar métricas
      final quizzesResult = await quizRepository.getKahoots(
        query: null,
        themes: [],
        orderBy: 'createdAt',
        order: 'desc',
      );

      quizzesResult.fold(
            (failure) => print("Error al obtener kahoots: $failure"),
            (quizList) {
          _totalQuizzes = quizList.length;
          _newKahootsCount = quizList
              .where((k) => k.createdAt.isAfter(weekAgo))
              .length;

          _calculatePopularity(themes, quizList);
        },
      );

    } catch (e) {
      print("Error inesperado en Dashboard: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculatePopularity(List<ThemeVO> themes, List<Kahoot> quizzes) {
    _categoryPopularity = {};
    for (var theme in themes) {
      final count = quizzes.where((q) => q.themes.contains(theme.name)).length;
      _categoryPopularity[theme.name] = count;
    }

    var sortedEntries = _categoryPopularity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _categoryPopularity = Map.fromEntries(sortedEntries);
  }
}