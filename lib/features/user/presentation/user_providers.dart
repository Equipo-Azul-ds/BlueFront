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
import '../../../core/config/api_config.dart';
import '../../groups/domain/repositories/GroupRepository.dart';
import '../../groups/infrastructure/repositories/group_repository_impl.dart';
import '../../groups/presentation/blocs/groups_bloc.dart';

class UserProviders extends StatelessWidget {
  final Widget child;

  const UserProviders({super.key, required this.child});

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

          final userRepo = UserRepositoryImpl(
            baseUrl: ApiConfigManager.httpBaseUrl,
            headersProvider: headersProvider,
            currentUserIdProvider: () async => await storage.read('currentUserId'),
            client: http.Client(),
          );

          return AuthBloc(
            repository: userRepo,
            createUser: CreateUserUseCase(userRepo),
            editUser: EditUserUseCase(userRepo),
            getCurrentUser: GetCurrentUserUseCase(userRepo),
            getUserByName: GetUserByNameUseCase(userRepo),
            updateSettings: UpdateUserSettingsUseCase(userRepo),
            storage: storage,
          );
        },
        child: MultiProvider(
          providers: [
            Provider<GroupRepository>(
              create: (context) {
                final storage = SecureStorage.instance;
                final headersProvider = () async {
                  final token = await storage.read('token');
                  final currentUserId = await storage.read('currentUserId');
                  return {
                    if (token != null) 'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                    // 'x-debug-user-id': currentUserId, // REMOVE: No longer used
                  };
                };
                return GroupRepositoryImpl(
                  baseUrl: ApiConfigManager.httpBaseUrl,
                  headersProvider: headersProvider,
                  client: http.Client(),
                );
              },
            ),
            ChangeNotifierProvider<GroupsBloc>(
              create: (context) => GroupsBloc(
                repository: context.read<GroupRepository>(),
                auth: context.read<AuthBloc>(),
              ),
            ),
          ],
          child: child,
        ),
      ),
    );
  }
}
