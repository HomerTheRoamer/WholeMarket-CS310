
import 'package:flutter/material.dart';

import 'models/product.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/inventory/inventory_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF237F75),
        ),
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

  final List<Product> products = [];

  void _changeTab(int index) {
    setState(() {
      selectedIndex = index;

      if (index == 0) {
        dashboardVersion++;
      }
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
          ),

          InventoryScreen(
            products: products,
          ),

          const _ComingSoonScreen(
            title: 'Pricing',
            icon: Icons.sell_outlined,
            description:
            'Competitor price tracking and smart '
                'discount suggestions will appear here.',
          ),

          const _ComingSoonScreen(
            title: 'Promos',
            icon: Icons.calendar_month_outlined,
            description:
            'Seasonal promotions and campaign '
                'planning will appear here.',
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _changeTab,
        labelBehavior:
        NavigationDestinationLabelBehavior.alwaysShow,
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

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _ComingSoonScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 70,
                color: const Color(0xFF237F75),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
