import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'common_pages/dashboard_page.dart';
import 'features/challenge/domain/repositories/single_player_game_repository.dart';
import 'features/challenge/infrastructure/repositories/single_player_game_repository_impl.dart';
import 'features/challenge/infrastructure/ports/slide_provider_impl.dart';
import 'features/challenge/application/use_cases/single_player_usecases.dart';
import 'features/challenge/application/ports/slide_provider.dart';
import 'features/challenge/presentation/blocs/single_player_challenge_bloc.dart';
import 'features/challenge/presentation/blocs/single_player_results_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SlideProvider>(create: (_) => SlideProviderImpl()),
        Provider<SinglePlayerGameRepositoryImpl>(
          create: (context) => SinglePlayerGameRepositoryImpl(
            slideProvider: context.read<SlideProvider>(),
          ),
        ),
        Provider<SinglePlayerGameRepository>(
          create: (context) => context.read<SinglePlayerGameRepositoryImpl>(),
        ),
        Provider<GetAttemptStateUseCase>(
          create: (context) => GetAttemptStateUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
          ),
        ),
        Provider<StartAttemptUseCase>(
          create: (context) => StartAttemptUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
            slideProvider: context.read<SlideProvider>(),
            getAttemptStateUseCase: context.read<GetAttemptStateUseCase>(),
          ),
        ),
        Provider<SubmitAnswerUseCase>(
          create: (context) => SubmitAnswerUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
            slideProvider: context.read<SlideProvider>(),
          ),
        ),
        Provider<GetSummaryUseCase>(
          create: (context) =>
              GetSummaryUseCase(context.read<SinglePlayerGameRepository>()),
        ),
        ChangeNotifierProvider<SinglePlayerChallengeBloc>(
          create: (context) => SinglePlayerChallengeBloc(
            startAttemptUseCase: context.read<StartAttemptUseCase>(),
            getAttemptStateUseCase: context.read<GetAttemptStateUseCase>(),
            submitAnswerUseCase: context.read<SubmitAnswerUseCase>(),
            getSummaryUseCase: context.read<GetSummaryUseCase>(),
          ),
        ),

        ChangeNotifierProvider<SinglePlayerResultsBloc>(
          create: (context) => SinglePlayerResultsBloc(
            repository: context.read<SinglePlayerGameRepository>(),
            getSummaryUseCase: context.read<GetSummaryUseCase>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trivvy',
        theme: ThemeData(
            fontFamily: 'Onest',
            primarySwatch: createMaterialColor(AppColor.primary),
            primaryColor: AppColor.primary,
            scaffoldBackgroundColor: AppColor.background,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColor.primary,
              iconTheme: IconThemeData(color: AppColor.onPrimary),
              titleTextStyle: TextStyle(color: AppColor.onPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: AppColor.secundary, foregroundColor: AppColor.onPrimary),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.secundary, foregroundColor: AppColor.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            iconTheme: IconThemeData(color: AppColor.primary),
            colorScheme: ColorScheme.fromSwatch(primarySwatch: createMaterialColor(AppColor.primary)).copyWith(secondary: AppColor.accent),
            pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
          ),
        initialRoute: '/dashboard',
        routes: {'/dashboard': (context) => DashboardPage()},
        home: DashboardPage(),
      ),
    );
  }
}
