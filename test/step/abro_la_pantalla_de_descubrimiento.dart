import 'package:Trivvy/features/discovery/domain/Repositories/IDiscoverRepository.dart';
import 'package:Trivvy/features/discovery/infraestructure/repositories/ThemeRepository.dart';
import 'package:Trivvy/features/discovery/presentation/pages/discover_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:Trivvy/features/discovery/presentation/pages/discover_page.dart';
import 'package:Trivvy/features/discovery/infraestructure/repositories/ThemeRepository.dart';
import 'package:Trivvy/features/discovery/domain/Repositories/IDiscoverRepository.dart';

Future<void> abroLaPantallaDeDescubrimiento(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<ThemeRepository>.value(value: GetIt.I<ThemeRepository>()),
          Provider<IDiscoverRepository>.value(value: GetIt.I<IDiscoverRepository>()),
        ],
        child: const Scaffold(body: DiscoverScreen()),
      ),
    ),
  );
  // Importante: pumpAndSettle porque initState usa Future.microtask
  await tester.pumpAndSettle();
}