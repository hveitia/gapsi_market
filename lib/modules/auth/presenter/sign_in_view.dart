import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_bloc.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_event.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/domain/credentials_validator.dart';
import 'package:rekluti_test/modules/auth/domain/sign_in.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_messages.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_routes.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_back_button.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_buttons.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_error_banner.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_field.dart';

/// Sign in form.
///
/// Nothing here navigates on success: the router's guard reacts to the bloc
/// reaching a signed in state, so there is a single place that decides where an
/// authenticated user belongs.
class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignInSubmitted(
          SignIn(email: _email.text, password: _password.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState state = context.watch<AuthBloc>().state;
    final FormSubmission submission = state is AuthSignedOut
        ? state.submission
        : const FormIdle();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppShapes.screenPadding,
            vertical: 12,
          ),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AuthBackButton(onPressed: () => context.pop()),
                  const SizedBox(height: 20),
                  Text('Hola de nuevo', style: AppTypography.titleLg),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar.',
                    style: AppTypography.body,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 20),
                          if (submission is FormRejected) ...<Widget>[
                            AuthErrorBanner(
                              message: AuthMessages.submission(
                                submission.reason,
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          AuthField(
                            label: 'Correo',
                            controller: _email,
                            hint: 'tu@correo.com',
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const <String>[AutofillHints.email],
                            validator: (String? value) => AuthMessages.email(
                              CredentialsValidator.validateEmail(value),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            label: 'Contraseña',
                            controller: _password,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[
                              AutofillHints.password,
                            ],
                            onSubmitted: _submit,
                            // Only presence is checked here. Telling someone
                            // their stored password is too short would be
                            // noise, and would leak the rules for free.
                            validator: (String? value) =>
                                (value ?? '').isEmpty
                                ? 'La contraseña es obligatoria'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: 'Entrar',
                    onPressed: _submit,
                    isLoading: submission is FormInProgress,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          context.pushReplacement(AuthRoutePaths.signUp),
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.label.copyWith(
                            color: AppColors.inkSoft,
                          ),
                          children: <InlineSpan>[
                            const TextSpan(text: '¿No tienes cuenta? '),
                            TextSpan(
                              text: 'Crear cuenta',
                              style: AppTypography.label.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
