import 'package:wholemarket/models/product.dart';
import 'package:flutter/material.dart';

class CreatePromotionScreen extends StatefulWidget {
  final List<Product> products;
  final Map<String, dynamic>? existingPromotion;

  final List<Map<String, dynamic>> existingPromotions;

  const CreatePromotionScreen({
    super.key,
    required this.products,
    this.existingPromotion,
    this.existingPromotions = const [],
  });

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();

  String? _selectedProductId;
  String _promotionType = 'Product';
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    final promotion = widget.existingPromotion;

    if (promotion != null) {
      _promotionType = promotion['type'] == 'Category' ? 'Category' : 'Product';
      if (_promotionType == 'Category') {
        _selectedCategory = promotion['category'] as String?;
      } else {
        _selectedProductId = promotion['productId'] as String?;
      }

      _discountController.text = (promotion['discount'] as double)
          .toStringAsFixed(0);

      _startDate = promotion['startDate'] as DateTime;
      _endDate = promotion['endDate'] as DateTime;
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 5),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;

        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first.')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both promotion dates.')),
      );
      return;
    }

    final products = widget.products;
    final isCategory = _promotionType == 'Category';
    final selectedProducts = isCategory
        ? products.where((item) => item.category == _selectedCategory).toList()
        : products.where((item) => item.id == _selectedProductId).toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product or category.')),
      );
      return;
    }

    final discount = double.parse(
      _discountController.text.trim().replaceAll(',', '.'),
    );

    // A category discount must be safe for every product in that category.
    for (final product in selectedProducts) {
      final expiration = DateTime(
        product.expirationDate.year,
        product.expirationDate.month,
        product.expirationDate.day,
      );
      if (_endDate!.isAfter(expiration)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promotion cannot end after ${product.name} expires '
              '(${_formatDate(expiration)}).',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final discountedPrice = product.sellingPrice * (1 - discount / 100);
      if (discountedPrice < product.unitCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${product.name}: discounted price '
              '(${discountedPrice.toStringAsFixed(2)} TL) is below cost '
              '(${product.unitCost.toStringAsFixed(2)} TL).',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    // Detect conflicts between product and category promotions too.
    final selectedIds = selectedProducts.map((item) => item.id).toSet();
    final hasOverlap = widget.existingPromotions.any((promotion) {
      if (identical(promotion, widget.existingPromotion)) return false;

      final existingStart = promotion['startDate'] as DateTime;
      final existingEnd = promotion['endDate'] as DateTime;
      final datesOverlap =
          !_endDate!.isBefore(existingStart) &&
          !_startDate!.isAfter(existingEnd);
      if (!datesOverlap) return false;

      final existingIds = promotion['type'] == 'Category'
          ? products
                .where((item) => item.category == promotion['category'])
                .map((item) => item.id)
                .toSet()
          : <String>{
              if (promotion['productId'] is String)
                promotion['productId'] as String,
            };
      return selectedIds.intersection(existingIds).isNotEmpty;
    });

    if (hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'A selected product already has a promotion during these dates.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final promotion = <String, dynamic>{
      'type': _promotionType,
      'productId': isCategory ? null : _selectedProductId,
      'category': isCategory ? _selectedCategory : null,
      'name': isCategory ? _selectedCategory! : selectedProducts.first.name,
      'discount': discount,
      'startDate': _startDate!,
      'endDate': _endDate!,
      'dates': '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          widget.existingPromotion == null
              ? 'Promotion created'
              : 'Promotion updated',
        ),
        content: const Text('Your promotion has been scheduled successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, promotion);
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingPromotion == null
              ? 'Create promotion'
              : 'Edit promotion',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'APPLIES TO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _promotionType,
                    decoration: const InputDecoration(
                      labelText: 'Applies to',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Product',
                        child: Text('Product'),
                      ),
                      DropdownMenuItem(
                        value: 'Category',
                        child: Text('Category'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _promotionType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_promotionType == 'Category')
                    DropdownButtonFormField<String>(
                      key: const ValueKey('category-selector'),
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Select category',
                        border: OutlineInputBorder(),
                      ),
                      items: products
                          .map((product) => product.category)
                          .toSet()
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Select a category' : null,
                    ),
                  if (_promotionType == 'Product')
                    DropdownButtonFormField<String>(
                      key: const ValueKey('product-selector'),
                      initialValue: _selectedProductId,
                      decoration: const InputDecoration(
                        hintText: 'Select a product',
                        border: OutlineInputBorder(),
                      ),
                      items: products.map((product) {
                        return DropdownMenuItem<String>(
                          value: product.id,
                          child: Text(product.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProductId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Select a product' : null,
                    ),

                  const SizedBox(height: 24),

                  const Text(
                    'DISCOUNT (%)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 20',
                      suffixText: '%',
                    ),
                    validator: (value) {
                      final discount = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );

                      if (discount == null ||
                          !discount.isFinite ||
                          discount <= 0 ||
                          discount > 100) {
                        return 'Enter a discount between 0 and 100';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'START DATE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_formatDate(_startDate)),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'END DATE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_formatDate(_endDate)),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _savePromotion,
                    child: Text(
                      widget.existingPromotion == null
                          ? 'Save promotion'
                          : 'Save changes',
                    ),
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
