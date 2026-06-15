import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import 'auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(AuthEmailSignUpRequested(
            name: _name.text,
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
            title: 'Create your account',
            subtitle: 'Start your journey with your AI companion',
            children: [
              if (!firebaseReady) const FirebaseUnavailableBanner(),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _name,
                      label: 'Name',
                      icon: Icons.person_outline,
                      enabled: firebaseReady && !busy,
                      validator: validateName,
                    ),
                    const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Create account',
                busy: busy,
                onPressed:
                    firebaseReady && !busy ? () => _submit(context) : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: busy ? null : () => context.pop(),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
