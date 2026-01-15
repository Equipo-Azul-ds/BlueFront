// This file is created to resolve the missing import issue in MediaRepositoryImpl.

import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

// Add your service registrations here.
void setupServiceLocator() {
  // Example:
  // sl.registerLazySingleton<YourService>(() => YourServiceImpl());
}