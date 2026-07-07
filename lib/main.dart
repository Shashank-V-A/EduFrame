import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'constants/theme.dart';
import 'screens/home_shell.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

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

  await DatabaseService.instance.database;
  await NotificationService.instance.init();
  await NotificationService.instance.rescheduleFromDatabase();

  runApp(const EduFrameApp());
}

class EduFrameApp extends StatelessWidget {
  const EduFrameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduFrame',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
