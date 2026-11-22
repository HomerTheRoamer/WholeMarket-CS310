import 'package:wholemarket/models/product.dart';
import 'package:flutter/material.dart';

import 'package:wholemarket/theme/app_colors.dart';

class AddCompetitorPriceScreen extends StatefulWidget {
  final List<Product> products;

  const AddCompetitorPriceScreen({super.key, required this.products});

  @override
  State<AddCompetitorPriceScreen> createState() =>
      _AddCompetitorPriceScreenState();
}

class _AddCompetitorPriceScreenState extends State<AddCompetitorPriceScreen> {
  // Used to validate the form
  final _formKey = GlobalKey<FormState>();

  // Controllers store what the user types
  final _storeController = TextEditingController();
  final _priceController = TextEditingController();

  // Product selected from the dropdown
  String? _selectedProductId;

  // Date selected by the user
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _storeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Opens the calendar
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Validates the form and saves the observation
  Future<void> _saveObservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final observation = {
      'productId': _selectedProductId!,
      'store': _storeController.text.trim(),
      'price': double.parse(_priceController.text.trim().replaceAll(',', '.')),
      'date': _selectedDate,
    };

    // Show confirmation dialog
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Observation saved'),
          content: const Text(
            'The competitor price has been recorded successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // Return the observation to Screen 09
    Navigator.pop(context, observation);
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add price observation')),
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
                    'PRODUCT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),

                  const SizedBox(height: 8),

                  // Product dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProductId,
                    decoration: const InputDecoration(
                      hintText: 'Select a product',
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
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a product';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'COMPETITOR / STORE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),

                  const SizedBox(height: 8),

                  // Competitor name input
                  TextFormField(
                    controller: _storeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Competitor A',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a competitor name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'OBSERVED PRICE (TL)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),

                  const SizedBox(height: 8),

                  // Competitor price input
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 47.50',
                      prefixText: '₺ ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a price';
                      }

                      final price = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );

                      if (price == null || !price.isFinite || price <= 0) {
                        return 'Enter a valid price greater than 0';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'OBSERVED ON',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),

                  const SizedBox(height: 8),

                  // Date selection
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.day}/'
                      '${_selectedDate.month}/'
                      '${_selectedDate.year}',
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _saveObservation,
                    child: const Text('Save observation'),
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
