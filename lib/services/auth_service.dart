import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'database_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const googleAndroidClientId =
      '669192163812-1955h44t69ueu40bqqt25v4o3jvp8k6a.apps.googleusercontent.com';
  static const googleWebClientId =
      '669192163812-1c4eglr4tpdpj0ovh2ff3i0fppucmjui.apps.googleusercontent.com';

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  final ValueNotifier<GoogleSignInAccount?> currentUser =
      ValueNotifier<GoogleSignInAccount?>(null);

  bool _initialized = false;

  bool get isConfigured =>
      googleWebClientId.trim().isNotEmpty &&
      googleAndroidClientId.trim().isNotEmpty;

  /// Google account subject / stable user id for the signed-in user.
  String? get currentUserId => currentUser.value?.id;

  Future<void> initialize() async {
    if (_initialized) return;

    await _signIn.initialize(
      clientId: googleAndroidClientId,
      serverClientId: isConfigured ? googleWebClientId : null,
    );

    _signIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          currentUser.value = event.user;
          _bindDatabase(event.user);
        case GoogleSignInAuthenticationEventSignOut():
          currentUser.value = null;
          DatabaseService.instance.unbindUser();
      }
    }).onError((Object error, StackTrace stackTrace) {
      debugPrint('GoogleSignIn error: $error');
    });

    final Future<GoogleSignInAccount?>? attempt =
        _signIn.attemptLightweightAuthentication();
    if (attempt != null) {
      final user = await attempt;
      currentUser.value = user;
      await _bindDatabase(user);
    }

    _initialized = true;
  }

  Future<void> _bindDatabase(GoogleSignInAccount? user) async {
    if (user == null) {
      await DatabaseService.instance.unbindUser();
      return;
    }
    final id = user.id;
    if (id.isEmpty) {
      debugPrint('Google user id is empty; database not bound');
      return;
    }
    await DatabaseService.instance.bindUser(id);
  }

  Future<void> signIn() async {
    if (!isConfigured) {
      throw Exception(
        'Google Sign-In is not configured yet.',
      );
    }
    if (!_signIn.supportsAuthenticate()) {
      throw Exception('Google Sign-In is not supported on this device.');
    }
    final user = await _signIn.authenticate();
    currentUser.value = user;
    await _bindDatabase(user);
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    currentUser.value = null;
    await DatabaseService.instance.unbindUser();
  }

  Future<String?> getIdToken() async {
    final user = currentUser.value;
    if (user == null) return null;
    return user.authentication.idToken;
  }

  Future<String?> getAccessToken({required List<String> scopes}) async {
    final user = currentUser.value;
    if (user == null) return null;
    if (scopes.isEmpty) return null;

    final auth = await user.authorizationClient.authorizeScopes(scopes);
    return auth.accessToken;
  }
}
