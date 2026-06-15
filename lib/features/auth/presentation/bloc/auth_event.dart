part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthEmailSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthEmailSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthEmailSignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const AuthEmailSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}
