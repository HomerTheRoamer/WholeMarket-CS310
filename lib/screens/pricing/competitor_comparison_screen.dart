import 'package:flutter/material.dart';

import 'add_competitor_price_screen.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:wholemarket_pricing/theme/app_colors.dart';
import 'package:wholemarket_pricing/models/sample_products.dart';

class CompetitorComparisonScreen extends StatefulWidget {
  const CompetitorComparisonScreen({super.key});

  @override
  State<CompetitorComparisonScreen> createState() =>
      _CompetitorComparisonScreenState();
}

class _CompetitorComparisonScreenState
    extends State<CompetitorComparisonScreen> {
  final List<Map<String, dynamic>> observations = [];

  @override
  void initState() {
    super.initState();
    _loadObservations();
  }

  Future<void> _saveObservations() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedObservations = observations.map((observation) {
      return {
        ...observation,
        'date': (observation['date'] as DateTime).toIso8601String(),
      };
    }).toList();

    await prefs.setString(
      'saved_competitor_observations',
      jsonEncode(encodedObservations),
    );
  }

  Future<void> _loadObservations() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('saved_competitor_observations');

    if (savedData == null) return;

    final decodedData = jsonDecode(savedData) as List<dynamic>;

    final loadedObservations = decodedData.map((item) {
      final observation = Map<String, dynamic>.from(item as Map);

      observation['date'] = DateTime.parse(observation['date'] as String);

      return observation;
    }).toList();

    if (!mounted) return;

    setState(() {
      observations
        ..clear()
        ..addAll(loadedObservations);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final products = SampleProducts.products;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Price comparison',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 4),

                  const Text('Manual observations'),

                  const SizedBox(height: 24),

                  // Pricing tabs
                  Row(
                    children: [
                      Expanded(
                        child: ActionChip(
                          label: const Text('Recommendations'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Chip(
                          label: const Text('Compare prices'),
                          backgroundColor: AppColors.accent,
                          side: BorderSide.none,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '${observations.length} price observations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 12),

                  // Scrollable competitor observations
                  Expanded(
                    child: observations.isEmpty
                        ? const Center(
                            child: Text(
                              'No competitor prices yet.\n'
                              'Add your first observation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          )
                        : ListView.builder(
                            itemCount: observations.length,
                            itemBuilder: (context, index) {
                              final observation = observations[index];

                              final product = products.firstWhere(
                                (item) => item.id == observation['productId'],
                              );

                              final competitorPrice =
                                  observation['price'] as double;

                              final difference =
                                  product.sellingPrice - competitorPrice;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          observation['store'] as String,
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 12,
                                          ),
                                        ),

                                        const SizedBox(height: 18),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Your price'),
                                            Text(
                                              '${product.sellingPrice.toStringAsFixed(2)} TL',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Competitor price'),
                                            Text(
                                              '${competitorPrice.toStringAsFixed(2)} TL',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        const Divider(),

                                        const SizedBox(height: 8),

                                        Text(
                                          difference > 0
                                              ? 'Your price is ${difference.toStringAsFixed(2)} TL higher.'
                                              : difference < 0
                                              ? 'Your price is ${difference.abs().toStringAsFixed(2)} TL lower.'
                                              : 'Both prices are equal.',
                                          style: const TextStyle(fontSize: 13),
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          'Observed on ${_formatDate(observation['date'] as DateTime)}',
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Values are manually entered and dated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final observation =
                          await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddCompetitorPriceScreen(),
                            ),
                          );

                      if (!context.mounted) return;

                      if (observation != null) {
                        setState(() {
                          observations.add(observation);
                        });
                        await _saveObservations();
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Competitor price added successfully!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add competitor price'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
