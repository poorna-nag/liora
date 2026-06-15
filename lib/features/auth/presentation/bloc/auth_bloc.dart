import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Drives the login / signup / forgot-password screens.
///
/// On a successful sign-in the [AuthRepository] flips its status, which the
/// router's redirect observes to navigate away — so this bloc only needs to
/// reflect submission progress and surface errors.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthEmailSignUpRequested>(_onEmailSignUp);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthGuestRequested>(_onGuest);
    on<AuthPasswordResetRequested>(_onPasswordReset);
  }

  bool get isFirebaseAvailable => _repository.isFirebaseAvailable;

  Future<void> _onEmailSignIn(
      AuthEmailSignInRequested event, Emitter<AuthState> emit) async {
    await _submit(
      emit,
      () => _repository.signInWithEmail(
        email: event.email,
        password: event.password,
      ),
    );
  }

  Future<void> _onEmailSignUp(
      AuthEmailSignUpRequested event, Emitter<AuthState> emit) async {
    await _submit(
      emit,
      () => _repository.signUpWithEmail(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );
  }

  Future<void> _onGoogleSignIn(
      AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    await _submit(emit, _repository.signInWithGoogle);
  }

  Future<void> _onGuest(
      AuthGuestRequested event, Emitter<AuthState> emit) async {
    await _submit(emit, _repository.continueAsGuest);
  }

  Future<void> _onPasswordReset(
      AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthFormStatus.submitting));
    try {
      await _repository.sendPasswordReset(event.email);
      emit(state.copyWith(status: AuthFormStatus.resetSent));
    } on Failure catch (f) {
      emit(state.copyWith(
          status: AuthFormStatus.failure, errorMessage: f.message));
    }
  }

  Future<void> _submit(
      Emitter<AuthState> emit, Future<void> Function() action) async {
    emit(state.copyWith(status: AuthFormStatus.submitting));
    try {
      await action();
      emit(state.copyWith(status: AuthFormStatus.success));
    } on Failure catch (f) {
      emit(state.copyWith(
          status: AuthFormStatus.failure, errorMessage: f.message));
    }
  }
}
