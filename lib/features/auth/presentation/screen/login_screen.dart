import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import 'auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(AuthEmailSignInRequested(
            email: _email.text,
            password: _password.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuthBloc>();
    final firebaseReady = bloc.isFirebaseAvailable;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: authErrorListener,
        builder: (context, state) {
          final busy = state.isSubmitting;
          return AuthScaffold(
            title: 'Welcome back',
            subtitle: 'Sign in to continue your conversations',
            children: [
              if (!firebaseReady) const FirebaseUnavailableBanner(),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: firebaseReady && !busy,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      enabled: firebaseReady && !busy,
                      validator: validatePassword,
                      onSubmitted: (_) => _submit(context),
                      suffix: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () => context.push(RouteNames.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 4),
              AuthPrimaryButton(
                label: 'Sign in',
                busy: busy,
                onPressed:
                    firebaseReady && !busy ? () => _submit(context) : null,
              ),
              const SizedBox(height: 16),
              const AuthDivider(),
              const SizedBox(height: 16),
              AuthOutlinedButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                onPressed: firebaseReady && !busy
                    ? () => bloc.add(const AuthGoogleSignInRequested())
                    : null,
              ),
              const SizedBox(height: 12),
              AuthOutlinedButton(
                label: 'Continue as guest',
                icon: Icons.person_outline,
                onPressed:
                    busy ? null : () => bloc.add(const AuthGuestRequested()),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed:
                        busy ? null : () => context.push(RouteNames.signup),
                    child: const Text('Sign up'),
                  ),
                ],
              ),
              Center(
                child: Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
