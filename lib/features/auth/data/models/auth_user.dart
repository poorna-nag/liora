import 'package:equatable/equatable.dart';

/// Presentation-facing identity for the auth feature.
///
/// Mirrors the active [UserContext] but adds the email shown on the account
/// screen. A guest is represented with [isGuest] true and a null [email].
class AuthUser extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final bool isGuest;

  const AuthUser({
    required this.id,
    required this.isGuest,
    this.email,
    this.displayName,
  });

  /// A friendly label for greetings ("Hi, Aditya").
  String get label {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return 'Guest';
  }

  @override
  List<Object?> get props => [id, email, displayName, isGuest];
}
