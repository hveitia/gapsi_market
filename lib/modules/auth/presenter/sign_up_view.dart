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
import 'package:rekluti_test/modules/auth/domain/sign_up.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_messages.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_routes.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_back_button.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_buttons.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_error_banner.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_field.dart';

/// Sign up form.
///
/// Like the sign in screen, it never navigates on success: reaching a signed in
/// state is what moves the user, and the router decides where.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignUpSubmitted(
          SignUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          ),
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
                  Text('Crear cuenta', style: AppTypography.titleLg),
                  const SizedBox(height: 8),
                  Text(
                    'Tus datos se guardan cifrados en este dispositivo. '
                    'No salen de tu teléfono.',
                    style: AppTypography.meta.copyWith(height: 1.5),
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
                            label: 'Nombre',
                            controller: _name,
                            hint: 'Tu nombre',
                            keyboardType: TextInputType.name,
                            autofillHints: const <String>[AutofillHints.name],
                            validator: (String? value) => AuthMessages.name(
                              CredentialsValidator.validateName(value),
                            ),
                          ),
                          const SizedBox(height: 14),
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
                              AutofillHints.newPassword,
                            ],
                            helper:
                                'Mínimo '
                                '${CredentialsValidator.minPasswordLength} '
                                'caracteres, con una letra y un número',
                            onSubmitted: _submit,
                            validator: (String? value) => AuthMessages.password(
                              CredentialsValidator.validatePassword(value),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: 'Crear cuenta',
                    onPressed: _submit,
                    isLoading: submission is FormInProgress,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          context.pushReplacement(AuthRoutePaths.signIn),
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.label.copyWith(
                            color: AppColors.inkSoft,
                          ),
                          children: <InlineSpan>[
                            const TextSpan(text: '¿Ya tienes cuenta? '),
                            TextSpan(
                              text: 'Inicia sesión',
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
