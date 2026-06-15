part of 'auth_bloc.dart';

enum AuthFormStatus { idle, submitting, success, failure, resetSent }

class AuthState extends Equatable {
  final AuthFormStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthFormStatus.idle,
    this.errorMessage,
  });

  bool get isSubmitting => status == AuthFormStatus.submitting;

  AuthState copyWith({
    AuthFormStatus? status,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, errorMessage];
}
