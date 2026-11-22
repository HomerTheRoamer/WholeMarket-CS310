import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../widgets/auth_ui.dart';

/// Screen 01. UI-only authentication, as required in CS310 Step 2.2.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continueToDemo() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => AccountPage(
        title: 'Welcome back',
        subtitle: 'Sign in to WholeMarket',
        showBack: false,
        logo: true,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoNotice(),
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
                hint: 'Enter password',
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: AccountValidators.password,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 20),
              AccountPrimaryButton(label: 'Sign in', onPressed: _continueToDemo),
              const SizedBox(height: 22),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.signUp),
                  child: const Text('New to WholeMarket? Create account'),
                ),
              ),
            ],
          ),
        ),
      );
}
