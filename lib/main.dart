import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'constants/theme.dart';
import 'l10n/app_strings.dart';
import 'screens/google_sign_in_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';
import 'services/theme_service.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

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

  Future<void> start() async {
    await AuthService.instance.initialize();
    await NotificationService.instance.init();
    if (DatabaseService.instance.activeUserId != null) {
      await NotificationService.instance.rescheduleFromDatabase();
    }
    await ThemeService.instance.load();
    await LocaleService.instance.load();
    runApp(const EduFrameApp());
  }

  if (_sentryDsn.trim().isEmpty) {
    await start();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = kReleaseMode ? 'production' : 'debug';
    },
    appRunner: start,
  );
}

class EduFrameApp extends StatelessWidget {
  const EduFrameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleService.instance.locale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'EduFrame',
              debugShowCheckedModeBanner: false,
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: themeMode,
              locale: locale,
              supportedLocales: AppStrings.supported.map(Locale.new).toList(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AuthGate(),
            );
          },
        );
      },
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
        return const AppEntryGate();
      },
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool? _onboardingDone;
  Object? _bindError;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final user = AuthService.instance.currentUser.value;
      final id = user?.id;
      if (id != null && id.isNotEmpty) {
        await DatabaseService.instance.bindUser(id);
        await NotificationService.instance.rescheduleFromDatabase();
      }
      final done = await OnboardingService.instance.isCompleted();
      if (!mounted) return;
      setState(() {
        _onboardingDone = done;
        _bindError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _bindError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bindError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not open your notebook: $_bindError'),
          ),
        ),
      );
    }
    if (_onboardingDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_onboardingDone == false) {
      return const OnboardingScreen();
    }
    return const HomeShell();
  }
}
