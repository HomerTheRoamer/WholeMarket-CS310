import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../navigation/app_routes.dart';
import '../../widgets/auth_ui.dart';

/// Screen 15. Any six digits advance in the UI demo; no real OTP is created.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (!_form.currentState!.validate()) return;
    Navigator.pushNamed(context, AppRoutes.resetPassword);
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments;
    final displayEmail = email is String && email.isNotEmpty ? email : 'name@example.com';
    return AccountPage(
      title: 'Email verification',
      subtitle: 'Enter the code from your inbox',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoNotice(message: 'UI demo only. Use any 6 digits to continue; no email is sent.'),
            Text('Email address: $displayEmail'),
            const SizedBox(height: 18),
            AccountField(
              label: 'VERIFICATION CODE',
              hint: 'Six-digit code',
              controller: _code,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              validator: (value) => value != null && RegExp(r'^\d{6}$').hasMatch(value)
                  ? null
                  : 'Enter six digits.',
            ),
            const SizedBox(height: 18),
            AccountPrimaryButton(label: 'Verify code', onPressed: _verify),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo only: no new code was sent.')),
                ),
                child: const Text('Resend code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
