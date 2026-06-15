import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(AuthPasswordResetRequested(_email.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuthBloc>();
    final firebaseReady = bloc.isFirebaseAvailable;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          authErrorListener(context, state);
          if (state.status == AuthFormStatus.resetSent) {
            context.pop();
          }
        },
        builder: (context, state) {
          final busy = state.isSubmitting;
          return AuthScaffold(
            title: 'Reset password',
            subtitle: "We'll email you a link to set a new password",
            children: [
              if (!firebaseReady) const FirebaseUnavailableBanner(),
              Form(
                key: _formKey,
                child: AuthTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: firebaseReady && !busy,
                  validator: validateEmail,
                  onSubmitted: (_) => _submit(context),
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Send reset link',
                busy: busy,
                onPressed:
                    firebaseReady && !busy ? () => _submit(context) : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: busy ? null : () => context.pop(),
                  child: const Text('Back to sign in'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
