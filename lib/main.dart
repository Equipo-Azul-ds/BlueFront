import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/library/domain/repositories/library_repository.dart';
import 'features/library/infrastructure/repositories/mock_library_repository.dart';
import 'features/library/application/get_kahoots_use_cases.dart';
import 'features/library/application/get_kahoot_detail_use_case.dart';
import 'features/library/presentation/providers/library_provider.dart';
import 'features/library/presentation/pages/library_page.dart';
import 'features/library/presentation/pages/kahoots_category_page.dart';
import 'common_pages/dashboard_page.dart';
import 'features/library/presentation/pages/kahoot_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LibraryRepository>(create: (_) => MockLibraryRepository()),
        Provider<GetCreatedKahootsUseCase>(
          create: (context) => GetCreatedKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetFavoriteKahootsUseCase>(
          create: (context) => GetFavoriteKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetInProgressKahootsUseCase>(
          create: (context) => GetInProgressKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetCompletedKahootsUseCase>(
          create: (context) => GetCompletedKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetKahootDetailUseCase>(
          create: (context) => GetKahootDetailUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LibraryProvider(
            getCreated: context.read<GetCreatedKahootsUseCase>(),
            getFavorite: context.read<GetFavoriteKahootsUseCase>(),
            getInProgress: context.read<GetInProgressKahootsUseCase>(),
            getCompleted: context.read<GetCompletedKahootsUseCase>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Trivvy',
        theme: ThemeData(primarySwatch: Colors.blue),

        initialRoute: '/dashboard',
        routes: {
          '/dashboard': (context) => DashboardPage(),
          '/library': (context) => const LibraryPage(),
          '/kahoots-category': (context) => const KahootsCategoryPage(),
          '/kahoot-detail': (context) => const KahootDetailPage(),
        },
        home: DashboardPage(),
      ),
    );
  }
}
