import 'package:equatable/equatable.dart';

/// Identity of the current app user.
///
/// In V1 this is always a guest with a locally-generated [userId]
/// (`guest_<uuid>`). In V2, once Firebase Authentication is added, the same
/// object is produced with `isGuest = false` and a Firebase uid — repositories
/// and storage scoping read [userId] only, so no downstream changes are needed.
class UserContext extends Equatable {
  final String userId;
  final bool isGuest;
  final String? displayName;

  const UserContext({
    required this.userId,
    required this.isGuest,
    this.displayName,
  });

  factory UserContext.guest(String userId) =>
      UserContext(userId: userId, isGuest: true);

  /// An authenticated user (Firebase uid). Storage scopes by [userId] only, so
  /// downstream repositories need no changes when transitioning from guest.
  factory UserContext.authenticated({
    required String userId,
    String? displayName,
  }) =>
      UserContext(userId: userId, isGuest: false, displayName: displayName);

  @override
  List<Object?> get props => [userId, isGuest, displayName];
}
