import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora/core/error/failures.dart';
import 'package:liora/features/auth/data/repositories/auth_repository.dart';
import 'package:liora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.isFirebaseAvailable).thenReturn(true);
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [submitting, success] on a successful email sign-in',
      build: () {
        when(() => repository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async {});
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthEmailSignInRequested(email: 'a@b.com', password: 'secret1'),
      ),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.submitting),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.success),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [submitting, failure] with the message when sign-in fails',
      build: () {
        when(() => repository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthFailure('Incorrect email or password.'));
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthEmailSignInRequested(email: 'a@b.com', password: 'wrong'),
      ),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.submitting),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Incorrect email or password.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [submitting, success] when continuing as guest',
      build: () {
        when(() => repository.continueAsGuest()).thenAnswer((_) async {});
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(const AuthGuestRequested()),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.submitting),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.success),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [submitting, resetSent] on a successful password reset',
      build: () {
        when(() => repository.sendPasswordReset(any()))
            .thenAnswer((_) async {});
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(const AuthPasswordResetRequested('a@b.com')),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.submitting),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthFormStatus.resetSent),
      ],
    );
  });
}
