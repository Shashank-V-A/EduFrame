import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
        case GoogleSignInAuthenticationEventSignOut():
          currentUser.value = null;
      }
    }).onError((Object error, StackTrace stackTrace) {
      debugPrint('GoogleSignIn error: $error');
    });

    final Future<GoogleSignInAccount?>? attempt =
        _signIn.attemptLightweightAuthentication();
    if (attempt != null) {
      currentUser.value = await attempt;
    }

    _initialized = true;
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
    await _signIn.authenticate();
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    currentUser.value = null;
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
