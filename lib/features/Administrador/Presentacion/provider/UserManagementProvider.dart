import 'package:flutter/material.dart';
import '../../Aplication/UseCases/DeleteUserUseCase.dart';
import '../../Aplication/UseCases/GetUserListUseCase.dart';
import '../../Aplication/UseCases/ToggleAdminUseCase.dart';
import '../../Aplication/UseCases/ToggleUserStatusUseCase.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/entidad/User.dart';



enum UserManagementState { initial, loading, loaded, error }


class UserManagementProvider with ChangeNotifier {
  final GetUserListUseCase getUserListUseCase;
  final ToggleUserStatusUseCase toggleUserStatusUseCase;
  final ToggleAdminRoleUseCase toggleAdminRoleUseCase; // UseCase nuevo
  final DeleteUserUseCase deleteUserUseCase;

  UserManagementProvider({
    required this.getUserListUseCase,
    required this.toggleUserStatusUseCase,
    required this.toggleAdminRoleUseCase,
    required this.deleteUserUseCase,
  });


  List<UserEntity> _users = [];
  UserManagementState _state = UserManagementState.initial;

  List<UserEntity> get users => _users;
  bool get isLoading => _state == UserManagementState.loading;
  bool get hasError => _state == UserManagementState.error;

  final UserQueryParams _defaultParams = const UserQueryParams(limit: 20, page: 1);



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

  Future<void> toggleBlockStatus(String userId) async {
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex == -1) return;

    final user = _users[userIndex];
    final String currentStatus = user.status == UserStatus.active ? 'Active' : 'Blocked';

    final result = await toggleUserStatusUseCase.execute(userId, currentStatus);

    result.fold(
          (failure) => print("Error al cambiar estado de bloqueo"),
          (updatedUser) {
        _users[userIndex] = updatedUser;
        notifyListeners();
      },
    );
  }


  Future<void> toggleAdminRole(String userId) async {
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex == -1) return;

    final user = _users[userIndex];


    final result = await toggleAdminRoleUseCase.execute(userId, user.isAdmin);

    result.fold(
          (failure) => print("Error al cambiar rol administrativo"),
          (updatedUser) {
        _users[userIndex] = updatedUser;
        notifyListeners();
      },
    );
  }

  Future<void> deleteUser(String userId) async {
    final result = await deleteUserUseCase.execute(userId);

    result.fold(
          (failure) {
        print("Error al eliminar permanentemente al usuario");
      },
          (_) {
        _users.removeWhere((user) => user.id == userId);
        notifyListeners();
      },
    );
  }
}