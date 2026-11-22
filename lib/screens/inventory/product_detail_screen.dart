import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../pricing/discount_recommendations_screen.dart';

/// Screen 07: detail of the selected product.
/// Editing and deletion are delegated to InventoryScreen so SQLite remains
/// the single source of truth and we reuse its existing validated form.
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Future<Product?> Function(Product product) onEdit;
  final Future<bool> Function(Product product) onDelete;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  String _date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String get _expiryLabel {
    final days = _product.daysUntilExpiry;
    if (days < 0) return 'Expired ${-days} day${days == -1 ? '' : 's'} ago';
    if (days == 0) return 'Expires today';
    return 'Expires in $days day${days == 1 ? '' : 's'}';
  }

  Future<void> _edit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.onEdit(_product);
      if (!mounted) return;
      if (updated != null) setState(() => _product = updated);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final deleted = await widget.onDelete(_product);
      if (!mounted) return;
      if (deleted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAdvice() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Discount advice')),
          body: DiscountRecommendationsScreen(products: [_product]),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final expired = _product.isExpired;
    final warning = _product.isExpiringSoon || expired;

    final statusBackground = expired
        ? colors.errorContainer
        : warning
            ? colors.tertiaryContainer
            : colors.primaryContainer;
    final statusForeground = expired
        ? colors.onErrorContainer
        : warning
            ? colors.onTertiaryContainer
            : colors.onPrimaryContainer;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Product details',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 175,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'PRODUCT IMAGE',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _product.name,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _expiryLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusForeground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 29),
                  _infoRow('Selling price', '${_product.sellingPrice.toStringAsFixed(2)} TL'),
                  const Divider(height: 1),
                  _infoRow('Unit cost', '${_product.unitCost.toStringAsFixed(2)} TL'),
                  const Divider(height: 1),
                  _infoRow('Quantity', '${_product.stockQuantity} units'),
                  const Divider(height: 1),
                  _infoRow('Expires', _date(_product.expirationDate)),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _showAdvice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'See discount advice',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : _edit,
                        child: const Text('Edit'),
                      ),
                      Text('·', style: TextStyle(color: colors.primary)),
                      TextButton(
                        onPressed: _busy ? null : _remove,
                        child: const Text('Remove product'),
                      ),
                    ],
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
