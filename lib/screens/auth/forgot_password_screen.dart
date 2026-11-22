import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../widgets/auth_ui.dart';

/// Screen 14. Demonstrates the recovery journey without sending an email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo flow: no verification email was sent.')),
    );
    Navigator.pushNamed(context, AppRoutes.verifyEmail, arguments: _email.text.trim());
  }

  @override
  Widget build(BuildContext context) => AccountPage(
        title: 'Forgot password',
        subtitle: 'Recover access to your WholeMarket account',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoNotice(),
              const Text('Enter the email address you would like to verify.'),
              const SizedBox(height: 20),
              AccountField(
                label: 'EMAIL ADDRESS',
                hint: 'Enter registered email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: AccountValidators.email,
              ),
              const SizedBox(height: 18),
              AccountPrimaryButton(label: 'Send code', onPressed: _next),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to sign in'),
                ),
              ),
            ],
          ),
        ),
      );
}
