import 'dart:async';

import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../storage/preferences_service.dart';
import 'user_context.dart';

/// Provides the current [UserContext] and notifies listeners of changes.
///
/// This is the single seam that V2 authentication plugs into: swap
/// [GuestSessionManager] for a `FirebaseSessionManager` (or have it transition
/// from guest to authenticated) without touching repositories or BLoCs.
abstract class SessionManager {
  /// The current user. Valid only after [init] completes.
  UserContext get current;

  /// Emits whenever the user context changes (e.g. guest -> authenticated).
  Stream<UserContext> get changes;

  /// Loads or creates the session identity. Must be called during startup.
  Future<void> init();

  /// Promotes the session to an authenticated identity (e.g. after Firebase
  /// sign-in). Emits on [changes].
  Future<void> signIn(UserContext user);

  /// Reverts the session to the local guest identity (e.g. after sign-out).
  /// Emits on [changes].
  Future<void> signOutToGuest();
}

/// V1 implementation: a persistent local guest identity.
class GuestSessionManager implements SessionManager {
  final PreferencesService _prefs;
  final _controller = StreamController<UserContext>.broadcast();

  UserContext? _current;

  GuestSessionManager(this._prefs);

  @override
  UserContext get current {
    final value = _current;
    if (value == null) {
      throw StateError('SessionManager.init() must be called before use.');
    }
    return value;
  }

  @override
  Stream<UserContext> get changes => _controller.stream;

  @override
  Future<void> init() async {
    var guestId = _prefs.getString(AppConstants.prefGuestId);
    if (guestId == null || guestId.isEmpty) {
      guestId = 'guest_${const Uuid().v4()}';
      await _prefs.setString(AppConstants.prefGuestId, guestId);
    }
    _current = UserContext.guest(guestId);
    _controller.add(_current!);
  }

  @override
  Future<void> signIn(UserContext user) async {
    _current = user;
    _controller.add(user);
  }

  @override
  Future<void> signOutToGuest() async {
    var guestId = _prefs.getString(AppConstants.prefGuestId);
    if (guestId == null || guestId.isEmpty) {
      guestId = 'guest_${const Uuid().v4()}';
      await _prefs.setString(AppConstants.prefGuestId, guestId);
    }
    _current = UserContext.guest(guestId);
    _controller.add(_current!);
  }

  void dispose() => _controller.close();
}
