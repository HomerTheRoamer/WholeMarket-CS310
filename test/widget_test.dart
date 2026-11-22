import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wholemarket/navigation/app_routes.dart';
import 'package:wholemarket/screens/auth/sign_in_screen.dart';
import 'package:wholemarket/screens/auth/sign_up_screen.dart';
import 'package:wholemarket/screens/auth/forgot_password_screen.dart';

void main() {
  testWidgets('Sign In displays its fields and shows inline errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SignInScreen(),
        routes: {
          AppRoutes.signUp: (_) => const SignUpScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        },
      ),
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('Create account opens the sign-up screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SignInScreen(),
        routes: { AppRoutes.signUp: (_) => const SignUpScreen() },
      ),
    );
    await tester.ensureVisible(find.text('New to WholeMarket? Create account'));
    await tester.tap(find.text('New to WholeMarket? Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Start managing your store'), findsOneWidget);
  });
}
