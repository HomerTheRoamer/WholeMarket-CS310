import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// A consistent, scrollable portrait layout for all account screens.
class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.logo = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final bool logo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: 'Back',
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                    if (logo) ...[
                      const SizedBox(height: 36),
                      Center(
                        child: Image.asset(
                          'assets/images/wholemarket_mark.png',
                          width: 88,
                          height: 88,
                          semanticLabel: 'WholeMarket store mark',
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Text(title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 7),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )),
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountField extends StatelessWidget {
  const AccountField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.inputFormatters,
    this.maxLength,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 19),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
      );
}

// The import for TextInputFormatter is exported by services.dart, not material.dart.
// Keep one shared widget for form fields so all six screens have identical spacing.
class AccountPrimaryButton extends StatelessWidget {
  const AccountPrimaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(onPressed: onPressed, child: Text(label)),
      );
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key, this.message = 'UI demo only. No real authentication or email is performed.'});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 12, color: AppColors.text)),
          ),
        ]),
      );
}

abstract final class AccountValidators {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(value.trim()) ? null : 'Enter a valid email address.';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Use at least 6 characters.';
    return null;
  }
}
