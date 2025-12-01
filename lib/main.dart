import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/gameSession/presentation/pages/join_game.dart';
import 'features/challenge/domain/repositories/SinglePlayerGameRepository.dart';
import 'features/challenge/infrastructure/repositories/SinglePlayerGameRepositoryImpl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<SinglePlayerGameRepository>(
      create: (_) => SinglePlayerGameRepositoryImpl(),
      dispose: (_, repo) {
        
      },
      child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trivvy',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const JoinGameScreen(),
      ),
    );
  }
}