import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'constants/theme.dart';
import 'screens/home_shell.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  // Open the database before first frame so startup never hits a race/crash.
  await DatabaseService.instance.database;

  runApp(const PlanBookApp());
}

class PlanBookApp extends StatelessWidget {
  const PlanBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlanBook',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
