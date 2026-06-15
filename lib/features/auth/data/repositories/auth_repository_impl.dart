import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/session/user_context.dart';
import '../../../../core/storage/preferences_service.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _auth;
  final SessionManager _session;
  final PreferencesService _prefs;

  final _statusController = StreamController<AuthStatus>.broadcast();
  AuthStatus _status = AuthStatus.unknown;
  AuthAccount? _account;

  AuthRepositoryImpl(this._auth, this._session, this._prefs);

  @override
  AuthStatus get status => _status;

  @override
  Stream<AuthStatus> get statusChanges => _statusController.stream;

  @override
  bool get isFirebaseAvailable => _auth.isAvailable;

  @override
  AuthUser? get currentUser {
    switch (_status) {
      case AuthStatus.authenticated:
        final a = _account;
        if (a == null) return null;
        return AuthUser(
          id: a.uid,
          email: a.email,
          displayName: a.displayName,
          isGuest: false,
        );
      case AuthStatus.guest:
        return AuthUser(id: _session.current.userId, isGuest: true);
      case AuthStatus.unknown:
      case AuthStatus.unauthenticated:
        return null;
    }
  }

  @override
  Future<void> bootstrap() async {
    // 1. An existing Firebase session wins.
    final account = _auth.currentAccount;
    if (account != null) {
      await _promote(account);
      return;
    }
    // 2. Otherwise honor the remembered choice.
    final choice = _prefs.getString(AppConstants.prefAuthChoice);
    if (choice == AppConstants.authChoiceGuest) {
      _emit(AuthStatus.guest);
    } else {
      _emit(AuthStatus.unauthenticated);
    }
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _run(() => _auth.signInWithEmail(email: email, password: password));

  @override
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) =>
      _run(() =>
          _auth.signUpWithEmail(name: name, email: email, password: password));

  @override
  Future<void> signInWithGoogle() => _run(_auth.signInWithGoogle);

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> continueAsGuest() async {
    await _prefs.setString(
        AppConstants.prefAuthChoice, AppConstants.authChoiceGuest);
    _emit(AuthStatus.guest);
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Best-effort; we still drop the local session.
    }
    await _session.signOutToGuest();
    await _prefs.remove(AppConstants.prefAuthChoice);
    _account = null;
    _emit(AuthStatus.unauthenticated);
  }

  /// Runs a Firebase sign-in action and promotes the session on success,
  /// converting low-level [AuthException]s into [AuthFailure]s.
  Future<void> _run(Future<AuthAccount> Function() action) async {
    try {
      final account = await action();
      await _promote(account);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> _promote(AuthAccount account) async {
    _account = account;
    await _session.signIn(UserContext.authenticated(
      userId: account.uid,
      displayName: account.displayName,
    ));
    await _prefs.setString(
        AppConstants.prefAuthChoice, AppConstants.authChoiceAuthenticated);
    _emit(AuthStatus.authenticated);
  }

  void _emit(AuthStatus status) {
    _status = status;
    _statusController.add(status);
  }
}
