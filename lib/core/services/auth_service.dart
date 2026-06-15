import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../error/exceptions.dart';

/// A lightweight, persistence-agnostic view of an authenticated account.
class AuthAccount {
  final String uid;
  final String? email;
  final String? displayName;

  const AuthAccount({required this.uid, this.email, this.displayName});
}

/// Wraps Firebase Authentication + Google Sign-In. Knows nothing about the app
/// session or storage — `AuthRepository` composes it with [SessionManager].
///
/// Guarded by [isAvailable] (mirrors Firebase init, same pattern as
/// `GeminiService`): when Firebase config is missing every Firebase-backed call
/// fails fast with a clear [AuthException] instead of crashing, while guest mode
/// continues to work entirely offline.
class AuthService {
  /// Web/Server OAuth client id, required on Android to obtain a Google idToken
  /// that Firebase will accept. Inject at build time:
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com`.
  static const String _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  bool _available = false;
  bool _googleInitialized = false;

  void markAvailable(bool value) => _available = value;
  bool get isAvailable => _available;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// The currently signed-in Firebase account, or null (also null when Firebase
  /// is unavailable).
  AuthAccount? get currentAccount {
    if (!_available) return null;
    final user = _auth.currentUser;
    return user == null ? null : _map(user);
  }

  /// Emits on sign-in / sign-out. Empty when Firebase is unavailable.
  Stream<AuthAccount?> authStateChanges() {
    if (!_available) return const Stream.empty();
    return _auth.authStateChanges().map((u) => u == null ? null : _map(u));
  }

  Future<AuthAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    } catch (_) {
      throw const AuthException('Sign in failed. Please try again.');
    }
  }

  Future<AuthAccount> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) {
        await user.updateDisplayName(trimmed);
        await user.reload();
      }
      return _map(_auth.currentUser ?? user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    } catch (_) {
      throw const AuthException('Could not create your account. Try again.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureAvailable();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    } catch (_) {
      throw const AuthException('Could not send the reset email. Try again.');
    }
  }

  Future<AuthAccount> signInWithGoogle() async {
    _ensureAvailable();
    try {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await google.initialize(
          serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
        );
        _googleInitialized = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google sign-in did not return a token.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      return _map(cred.user!);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    } catch (_) {
      // Covers user-cancellation and platform/configuration errors.
      throw const AuthException('Google sign-in was cancelled or failed.');
    }
  }

  Future<void> signOut() async {
    if (!_available) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore — the user may not have used Google sign-in.
    }
    await _auth.signOut();
  }

  AuthAccount _map(User user) => AuthAccount(
        uid: user.uid,
        email: user.email,
        displayName: (user.displayName?.isNotEmpty ?? false)
            ? user.displayName
            : user.email?.split('@').first,
      );

  void _ensureAvailable() {
    if (!_available) {
      throw const AuthException(
        'Accounts are unavailable. Add your Firebase config (see README) or '
        'continue as a guest.',
      );
    }
  }

  /// Maps Firebase error codes to friendly, user-facing messages.
  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'network-request-failed':
        return 'No internet connection. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
