import 'package:flutter/material.dart';

import 'competitor_comparison_screen.dart';

import 'package:wholemarket_pricing/screens/promotions/promotion_planner_screen.dart';
import 'package:wholemarket_pricing/theme/app_colors.dart';
import 'package:wholemarket_pricing/models/product.dart';
import 'package:wholemarket_pricing/models/sample_products.dart';
import 'package:wholemarket_pricing/services/discount_service.dart';

class DiscountRecommendationsScreen extends StatelessWidget {
  const DiscountRecommendationsScreen({super.key});

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
                  // Screen title
                  Text(
                    'Pricing insights',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 4),

                  const Text('Rules-based suggestions'),

                  const SizedBox(height: 24),

                  // Pricing tabs
                  Row(
                    children: [
                      Expanded(
                        child: Chip(
                          label: const Text('Recommendations'),
                          backgroundColor: AppColors.accent,
                          side: BorderSide.none,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: ActionChip(
                          label: const Text('Compare prices'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CompetitorComparisonScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '${products.length} products',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 12),

                  // Dynamic product list
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildProductCard(product),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PromotionPlannerScreen(),
                        ),
                      );
                    },

                    child: const Text('Plan a promotion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final daysLeft = product.daysUntilExpiration;

    final expiryDiscount = DiscountService.expirationDiscount(daysLeft);

    final seasonDiscount = DiscountService.seasonalDiscount(
      product.peakSeason,
      DiscountService.currentSeason(DateTime.now()),
    );

    final discount = DiscountService.recommendedDiscount(
      daysLeft: daysLeft,
      peakSeason: product.peakSeason,
      today: DateTime.now(),
    );

    final discountedPrice = DiscountService.discountedPrice(
      product.sellingPrice,
      discount,
    );

    final isAboveCost = DiscountService.isAboveCost(
      product.sellingPrice,
      product.unitCost,
      discount,
    );

    String reason;

    if (product.isExpired) {
      reason =
          'This product has expired. '
          'It is not eligible for promotion.';
    } else if (discount == 0) {
      reason = 'No promotion is currently recommended.';
    } else if (expiryDiscount >= seasonDiscount) {
      reason =
          'This product is approaching its expiration '
          'date. A discount may help reduce waste.';
    } else {
      reason =
          'This product is outside its peak season. '
          'A promotion may help increase demand.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            Text(
              product.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              product.category,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            // Expiration information
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.isExpired ? 'Expired' : '$daysLeft days left',
                style: const TextStyle(
                  color: AppColors.warningText,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Suggested discount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Suggested discount'),

                Text(
                  product.isExpired
                      ? 'Not eligible'
                      : '${discount.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: product.isExpired
                        ? AppColors.error
                        : AppColors.primary,
                    fontSize: product.isExpired ? 14 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Current and suggested prices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current price'),
                Text('${product.sellingPrice.toStringAsFixed(2)} TL'),
              ],
            ),

            if (!product.isExpired) ...[
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Suggested price'),

                  Text(
                    '${discountedPrice.toStringAsFixed(2)} TL',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 8),

            const Text(
              'Why this suggestion?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(reason, style: const TextStyle(fontSize: 13)),

            if (!product.isExpired && discount > 0 && !isAboveCost) ...[
              const SizedBox(height: 10),

              const Text(
                'Warning: Suggested price is below unit cost.',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
