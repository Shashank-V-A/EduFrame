import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'constants/theme.dart';
import 'screens/google_sign_in_screen.dart';
import 'screens/home_shell.dart';
import 'services/auth_service.dart';
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
  await AuthService.instance.initialize();
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GoogleSignInAccount?>(
      valueListenable: AuthService.instance.currentUser,
      builder: (context, user, _) {
        if (user == null) {
          return const GoogleSignInScreen();
        }
        return const HomeShell();
      },
    );
  }
}
