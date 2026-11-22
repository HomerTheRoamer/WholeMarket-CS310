import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/pricing/discount_recommendations_screen.dart';

void main() {
  runApp(const WholeMarketApp());
}

class WholeMarketApp extends StatelessWidget {
  const WholeMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WholeMarket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DiscountRecommendationsScreen(),
    );
  }
}

class PricingTestScreen extends StatelessWidget {
  const PricingTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WholeMarket')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing insights',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Rules-based suggestions'),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Milk 1 L'),
                    SizedBox(height: 12),
                    Text('Suggested discount: 10%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Plan a promotion'),
            ),
          ],
        ),
      ),
    );
  }
}
