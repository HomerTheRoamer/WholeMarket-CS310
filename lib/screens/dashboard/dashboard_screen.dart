import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/discount_service.dart';

import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../models/product.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onViewPricing;
  final VoidCallback onExpiringSoon;
  final VoidCallback onActiveOffers;
  final VoidCallback onPriceGaps;
  final VoidCallback onSuggestions;
  final VoidCallback? onProfile;

  const DashboardScreen({
    super.key,
    required this.onAddProduct,
    required this.onViewPricing,
    required this.onExpiringSoon,
    required this.onActiveOffers,
    required this.onPriceGaps,
    required this.onSuggestions,
    this.onProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Product> products = [];
  bool isLoading = true;
  int activeOffers = 0;
  int priceGaps = 0;
  int suggestions = 0;

  static const Color primaryColor = Color(0xFF237F75);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final savedProducts = await DatabaseHelper.instance.getProducts();

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final savedPromotions =
      jsonDecode(prefs.getString('saved_promotions') ?? '[]') as List;
      final savedObservations = jsonDecode(
        prefs.getString('saved_competitor_observations') ?? '[]',
      ) as List;
      final active = savedPromotions.where((entry) {
        final promotion = entry as Map;
        final start = DateTime.parse(promotion['startDate'] as String);
        final end = DateTime.parse(promotion['endDate'] as String);
        final today = DateTime(now.year, now.month, now.day);
        return !today.isBefore(DateTime(start.year, start.month, start.day)) &&
            !today.isAfter(DateTime(end.year, end.month, end.day));
      }).length;
      final byId = {for (final product in savedProducts) product.id: product};
      final gaps = savedObservations.where((entry) {
        final observation = entry as Map;
        final product = byId[observation['productId']];
        if (product == null) return false;
        final price = (observation['price'] as num).toDouble();
        return price < product.sellingPrice;
      }).length;
      final recommended = savedProducts.where((product) {
        if (product.isExpired) return false;
        final discount = DiscountService.recommendedDiscount(
          daysLeft: product.daysUntilExpiry,
          peakSeason: product.season,
          today: now,
        );
        return discount > 0 &&
            DiscountService.isAboveCost(
              product.sellingPrice,
              product.unitCost,
              discount,
            );
      }).length;
      if (!mounted) return;

      setState(() {
        activeOffers = active;
        priceGaps = gaps;
        suggestions = recommended;
        products = savedProducts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Database error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiringSoon = products
        .where((product) => product.isExpiringSoon)
        .toList();

    final attentionProducts = products
        .where((product) => product.isExpired || product.isExpiringSoon)
        .toList();

    attentionProducts.sort(
          (a, b) => a.expirationDate.compareTo(b.expirationDate),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadProducts,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(),

              const SizedBox(height: 8),

              const Text(
                'Your store at a glance',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Expiring soon',
                      '${expiringSoon.length}',
                      Icons.access_time,
                      onTap: widget.onExpiringSoon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Active offers',
                      '$activeOffers',
                      Icons.local_offer_outlined,
                      onTap: widget.onActiveOffers,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Price gaps',
                      '$priceGaps',
                      Icons.compare_arrows,
                      onTap: widget.onPriceGaps,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Suggestions',
                      '$suggestions',
                      Icons.lightbulb_outline,
                      onTap: widget.onSuggestions,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Needs attention',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF20343E),
                ),
              ),

              const SizedBox(height: 14),

              if (attentionProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _boxDecoration(),
                  child: const Text(
                    'No products need attention.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                )
              else
                ...attentionProducts.map(
                      (product) => _attentionCard(product),
                ),

              const SizedBox(height: 30),

              const Text(
                'Quick actions',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF20343E),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onAddProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Add product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onViewPricing,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF20343E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View pricing'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Good morning,',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF20343E),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: widget.onProfile,
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Profile'),
          style: TextButton.styleFrom(foregroundColor: primaryColor),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadProducts,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 115,
          padding: const EdgeInsets.all(15),
          decoration: _boxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 17, color: primaryColor),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attentionCard(Product product) {
    final expired = product.isExpired;
    final days = product.daysUntilExpiry;

    final String status;

    if (expired) {
      status = 'Expired';
    } else if (days == 0) {
      status = 'Expires today';
    } else if (days == 1) {
      status = '1 day left';
    } else {
      status = '$days days left';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: expired
                  ? const Color(0xFFFDEBEC)
                  : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: expired ? Colors.red : const Color(0xFFBA7800),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              '${product.name} · '
                  '${product.stockQuantity} units',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF20343E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD9E4E8)),
    );
  }
}
