import 'package:flutter/material.dart';

import 'models/product.dart';
import 'database/database_helper.dart';
import 'screens/pricing/discount_recommendations_screen.dart';
import 'screens/promotions/promotion_planner_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/pricing/competitor_comparison_screen.dart';

void main() {
  runApp(const WholeMarketApp());
}

class WholeMarketApp extends StatelessWidget {
  const WholeMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WholeMarket',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237F75)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

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
    // Inventory persists its changes to SQLite. Refresh the shared list
    // before showing pricing or promotions, so all tabs see the same data.
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
