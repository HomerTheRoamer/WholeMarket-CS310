/// Named routes shared by the account UI and the existing HomeScreen shell.
/// Each path is registered by MaterialApp in lib/main.dart.
abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const profile = '/profile';
}
