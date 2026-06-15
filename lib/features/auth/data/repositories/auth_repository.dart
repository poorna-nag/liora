import '../models/auth_user.dart';

/// High-level authentication state used to gate navigation.
enum AuthStatus {
  /// Startup default, before [AuthRepository.bootstrap] resolves.
  unknown,

  /// No account and no guest choice yet — show the login screen.
  unauthenticated,

  /// Signed in with Firebase (email or Google).
  authenticated,

  /// Chose to continue without an account.
  guest,
}

/// Single source of truth for who the user is and how they got here.
///
/// Drives the router's redirect (via [status] + [statusChanges]) and the auth
/// screens (via the [AuthBloc]). Backed by [AuthService] (Firebase) and
/// [SessionManager] (identity used for per-user storage scoping).
abstract class AuthRepository {
  /// Current high-level status (synchronous; safe to read in a router redirect).
  AuthStatus get status;

  /// The current user, or null when [status] is unknown/unauthenticated.
  AuthUser? get currentUser;

  /// Emits whenever [status] changes — wired to the router's refreshListenable.
  Stream<AuthStatus> get statusChanges;

  /// Whether Firebase is configured (controls account-based sign-in options).
  bool get isFirebaseAvailable;

  /// Resolves the initial [status] from any existing Firebase session or the
  /// remembered guest choice. Called once during startup.
  Future<void> bootstrap();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  /// Enters the app without an account (remembered across launches).
  Future<void> continueAsGuest();

  /// Signs out and returns to the unauthenticated state.
  Future<void> signOut();
}
