import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../navigation/app_routes.dart';
import '../../widgets/auth_ui.dart';

/// Screen 02. Saves only demo display information, never passwords.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _store = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _store.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continueToDemo() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_owner_name', _name.text.trim());
      await prefs.setString('demo_store_name', _store.text.trim());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Form complete'),
          content: const Text('Your demo profile is ready. No account was created.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save demo profile. Please retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AccountPage(
        title: 'Create account',
        subtitle: 'Start managing your store',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoNotice(),
              AccountField(
                label: 'FULL NAME',
                hint: 'Enter your name',
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: AccountValidators.requiredText,
              ),
              AccountField(
                label: 'STORE NAME',
                hint: 'Enter shop name',
                controller: _store,
                textInputAction: TextInputAction.next,
                validator: AccountValidators.requiredText,
              ),
              AccountField(
                label: 'EMAIL',
                hint: 'Enter email address',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: AccountValidators.email,
              ),
              AccountField(
                label: 'PASSWORD',
                hint: 'Create password',
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: AccountValidators.password,
              ),
              const SizedBox(height: 12),
              AccountPrimaryButton(
                label: _saving ? 'Preparing demo...' : 'Create account',
                onPressed: _saving ? null : _continueToDemo,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Sign in'),
                ),
              ),
            ],
          ),
        ),
      );
}
