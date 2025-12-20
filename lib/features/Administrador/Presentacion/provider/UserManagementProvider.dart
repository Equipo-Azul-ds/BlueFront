import 'package:flutter/material.dart';
import '../../Aplication/UseCases/GetUserListUseCase.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/entidad/User.dart';


// Definición de estados de UI
enum UserManagementState { initial, loading, loaded, error }

class UserManagementProvider with ChangeNotifier {
  final GetUserListUseCase getUserListUseCase;

  UserManagementProvider({required this.getUserListUseCase});

  // Estado interno
  List<UserEntity> _users = [];
  UserManagementState _state = UserManagementState.initial;

  // Getters para la UI
  List<UserEntity> get users => _users;
  bool get isLoading => _state == UserManagementState.loading;
  bool get hasError => _state == UserManagementState.error;

  // Parámetros de consulta por defecto
  final UserQueryParams _defaultParams = const UserQueryParams(limit: 20, page: 1);

  // --- LÓGICA DE NEGOCIO ---

  Future<void> loadUsers(String adminId) async {
    _state = UserManagementState.loading;
    notifyListeners();

    final result = await getUserListUseCase.execute(params: _defaultParams);

    result.fold(
      (failure) {
        _state = UserManagementState.error;
        _users = [];
        print('Error al cargar usuarios: $failure');
      },
      (paginatedList) {
        _state = UserManagementState.loaded;
        _users = paginatedList.users;
      },
    );
    notifyListeners();
  }

  void toggleBlockStatus(String userId) {
    // Implementación temporal para actualizar la UI localmente
    _users = _users.map((u) {
      if (u.id == userId) {
        final newStatus = u.isBlocked ? UserStatus.active : UserStatus.blocked;
        return UserEntity(
          id: u.id, name: u.name, email: u.email, description: u.description,
          userType: u.userType, createdAt: u.createdAt, status: newStatus,
        );
      }
      return u;
    }).toList();
    notifyListeners();
  }

  void deleteUser(String userId) {
    // Implementación temporal para actualizar la UI localmente
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }
}