import 'package:flutter/material.dart';
import '../../Aplication/UseCases/DeleteUserUseCase.dart';
import '../../Aplication/UseCases/GetUserListUseCase.dart';
import '../../Aplication/UseCases/ToggleUserStatusUseCase.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/entidad/User.dart';


// Definición de estados de UI
enum UserManagementState { initial, loading, loaded, error }


class UserManagementProvider with ChangeNotifier {
  final GetUserListUseCase getUserListUseCase;
  final ToggleUserStatusUseCase toggleUserStatusUseCase;
  final DeleteUserUseCase deleteUserUseCase;


  UserManagementProvider({required this.getUserListUseCase,
    required this.toggleUserStatusUseCase,
    required this.deleteUserUseCase,});

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

  // Lógica para bloquear/desbloquear
  Future<void> toggleBlockStatus(String userId) async {
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex == -1) return;

    final currentStatus = _users[userIndex].status == UserStatus.active ? 'active' : 'blocked';

    final result = await toggleUserStatusUseCase.execute(userId, currentStatus);

    result.fold(
          (failure) => print("Error al cambiar estado"),
          (updatedUser) {
        _users[userIndex] = updatedUser;
        notifyListeners(); // Actualiza la lista en la pantalla
      },
    );
  }

  // Lógica para eliminar
  Future<void> deleteUser(String userId) async {
    final result = await deleteUserUseCase.execute(userId);

    result.fold(
          (failure) => print("Error al eliminar"),
          (_) {
        _users.removeWhere((u) => u.id == userId);
        notifyListeners(); // Elimina de la UI inmediatamente
      },
    );
  }
}