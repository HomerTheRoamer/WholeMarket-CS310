import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/product.dart';
import 'database/database_helper.dart';
import 'screens/pricing/discount_recommendations_screen.dart';
import 'screens/promotions/promotion_planner_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/pricing/competitor_comparison_screen.dart';

// Group 24 – Screen 01/02/13/14/15/16 and app-wide navigation.
import 'navigation/app_routes.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/account/profile_settings_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WholeMarketApp());
}

class WholeMarketApp extends StatefulWidget {
  const WholeMarketApp({super.key});

  @override
  State<WholeMarketApp> createState() => _WholeMarketAppState();
}

class _WholeMarketAppState extends State<WholeMarketApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _themeMode =
            (prefs.getBool('wholemarket_dark_mode') ?? false)
                ? ThemeMode.dark
                : ThemeMode.light);
      }
    } catch (_) {
      // Keep light mode if preferences are unavailable in a UI test.
    }
  }

  void _changeTheme(bool dark) {
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
    _persistThemePreference(dark);
  }

  Future<void> _persistThemePreference(bool dark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wholemarket_dark_mode', dark);
    } catch (_) {
      // A preference write failure should not crash the UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    final light = AppTheme.lightTheme;
    final dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WholeMarket',
      theme: light.copyWith(
        textTheme: GoogleFonts.interTextTheme(light.textTheme),
      ),
      darkTheme: dark.copyWith(
        textTheme: GoogleFonts.interTextTheme(dark.textTheme),
      ),
      themeMode: _themeMode,
      initialRoute: AppRoutes.signIn,
      routes: {
        AppRoutes.signIn: (_) => const SignInScreen(),
        AppRoutes.signUp: (_) => const SignUpScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.verifyEmail: (_) => const EmailVerificationScreen(),
        AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.profile: (_) => ProfileSettingsScreen(
          onThemeChanged: _changeTheme,
        ),
      },
    );
  }
}

/// Existing teammate main tab shell, preserved and extended with Profile route.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int dashboardVersion = 0;
  int dataVersion = 0;
  int inventoryVersion = 0;
  bool showActiveOffers = false;
  int initialInventoryFilter = 0;

  void _openExpiringSoon() {
    setState(() {
      initialInventoryFilter = 1;
      inventoryVersion++;
      selectedIndex = 1;
    });
  }

  Future<void> _openActiveOffers() async {
    setState(() => showActiveOffers = true);
    await _changeTab(3, keepActiveFilter: true);
  }

  Future<void> _openPriceGaps() async {
    try {
      final latest = await DatabaseHelper.instance.getProducts();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CompetitorComparisonScreen(products: latest),
        ),
      );
      if (mounted) setState(() => dashboardVersion++);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open price comparison: $error')),
      );
    }
  }

  final List<Product> products = [];

  Future<void> _changeTab(int index, {bool keepActiveFilter = false}) async {
    if (index == 1) {
      initialInventoryFilter = 0;
      inventoryVersion++;
    }
    if (index == 3 && !keepActiveFilter) showActiveOffers = false;
    // Inventory persists changes to SQLite. Refresh before pricing/promos.
    if (index == 2 || index == 3) {
      try {
        final latest = await DatabaseHelper.instance.getProducts();
        if (!mounted) return;
        setState(() {
          products
            ..clear()
            ..addAll(latest);
          dataVersion++;
          selectedIndex = index;
        });
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load products: $error')),
        );
      }
      return;
    }
    setState(() {
      selectedIndex = index;
      if (index == 0) dashboardVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          DashboardScreen(
            key: ValueKey(dashboardVersion),
            onAddProduct: () => _changeTab(1),
            onViewPricing: () => _changeTab(2),
            onExpiringSoon: _openExpiringSoon,
            onActiveOffers: _openActiveOffers,
            onPriceGaps: _openPriceGaps,
            onSuggestions: () => _changeTab(2),
            onProfile: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          InventoryScreen(
            key: ValueKey('inventory-$inventoryVersion'),
            products: products,
            initialExpiryFilter: initialInventoryFilter,
          ),
          DiscountRecommendationsScreen(
            key: ValueKey('pricing-$dataVersion'),
            products: products,
          ),
          PromotionPlannerScreen(
            key: ValueKey('promos-$dataVersion'),
            products: products,
            initialShowActiveOnly: showActiveOffers,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _changeTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined),
            selectedIcon: Icon(Icons.sell),
            label: 'Pricing',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Promos',
          ),
        ],
      ),
    );
  }
}
