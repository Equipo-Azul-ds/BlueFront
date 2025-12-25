import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../domain/repositories/UserRepository.dart';
import '../infrastructure/repositories/user_repository_impl.dart';
import '../application/create_user_usecase.dart';
import '../application/edit_user_usecase.dart';
import '../application/get_current_user_usecase.dart';
import '../application/get_user_by_name_usecase.dart';
import '../application/update_user_settings_usecase.dart';
import '../presentation/blocs/auth_bloc.dart';
import '../../../local/secure_storage.dart';

class UserProviders extends StatelessWidget {
  final Widget child;
  final String baseUrl;

  const UserProviders({super.key, required this.child, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return Provider<SecureStorage>.value(
      value: SecureStorage.instance,
      child: ChangeNotifierProvider<AuthBloc>(
        create: (_) {
          final storage = SecureStorage.instance;
          final headersProvider = () async {
            final token = await storage.read('token');
            return {
              if (token != null) 'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            };
          };

          final repo = UserRepositoryImpl(
            baseUrl: baseUrl,
            headersProvider: headersProvider,
            currentUserIdProvider: () async => await storage.read('currentUserId'),
            client: http.Client(),
          );

          return AuthBloc(
            repository: repo,
            createUser: CreateUserUseCase(repo),
            editUser: EditUserUseCase(repo),
            getCurrentUser: GetCurrentUserUseCase(repo),
            getUserByName: GetUserByNameUseCase(repo),
            updateSettings: UpdateUserSettingsUseCase(repo),
            storage: storage,
          );
        },
        child: child,
      ),
    );
  }
}
