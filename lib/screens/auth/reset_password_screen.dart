import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../widgets/auth_ui.dart';

/// Screen 16. Validates inputs but deliberately does not change credentials.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Form completed'),
        content: const Text('Password reset preview finished. No real password was changed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signIn, (_) => false);
  }

  @override
  Widget build(BuildContext context) => AccountPage(
        title: 'Reset password',
        subtitle: 'Choose a new password',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoNotice(),
              AccountField(
                label: 'NEW PASSWORD',
                hint: 'Enter new password',
                controller: _password,
                obscureText: true,
                validator: AccountValidators.password,
              ),
              AccountField(
                label: 'CONFIRM PASSWORD',
                hint: 'Re-enter new password',
                controller: _confirm,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm the password.';
                  return value == _password.text ? null : 'Passwords do not match.';
                },
              ),
              const SizedBox(height: 18),
              AccountPrimaryButton(label: 'Update password', onPressed: _submit),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.signIn, (_) => false),
                  child: const Text('Return to sign in'),
                ),
              ),
            ],
          ),
        ),
      );
}
