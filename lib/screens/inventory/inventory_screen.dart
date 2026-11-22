import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../database/database_helper.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  final List<Product> products;
  final int initialExpiryFilter;

  const InventoryScreen({
    super.key,
    required this.products,
    this.initialExpiryFilter = 0,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String searchText = '';
  // 0 = All, 1 = Next 7 days, 2 = Expired, 3 = Custom, 4 = Next 30 days
  int expiryFilter = 0;
  DateTime? customStartDate;
  DateTime? customEndDate;
  bool isLoading = true;

  final List<String> categories = [
    'Dairy',
    'Beverages',
    'Bakery',
    'Fruits & Vegetables',
    'Meat',
    'Snacks',
    'Frozen Foods',
    'Cleaning',
    'Personal Care',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    expiryFilter = widget.initialExpiryFilter;
    _loadData();
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _addCategoryToList(String name) {
    if (name.trim().isEmpty) return;

    final exists = categories.any(
      (category) => category.toLowerCase() == name.toLowerCase(),
    );

    if (!exists) {
      categories.add(name);
    }
  }

  Future<void> _loadData() async {
    try {
      final savedProducts = await DatabaseHelper.instance.getProducts();

      final savedCategories = await DatabaseHelper.instance.getCategories();

      if (!mounted) return;

      setState(() {
        widget.products
          ..clear()
          ..addAll(savedProducts);

        for (final category in savedCategories) {
          _addCategoryToList(category);
        }

        for (final product in savedProducts) {
          _addCategoryToList(product.category);
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showError('Database error: $e');
    }
  }

  Future<Product?> _openProductForm([Product? existing]) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (context) =>
          _ProductFormDialog(product: existing, categories: categories),
    );

    if (!mounted || result == null) return null;

    try {
      // INSERT OR REPLACE:
      // Works for new products and existing products.
      await DatabaseHelper.instance.insertProduct(result);

      // Read the latest data directly from SQLite.
      await _loadData();

      if (!mounted) return result;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully')),
      );
      return result;
    } catch (e) {
      _showError('Failed to save product: $e');
      return null;
    }
  }

  Future<bool> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete ${product.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return false;

    try {
      await DatabaseHelper.instance.deleteProduct(product.id);

      await _loadData();

      if (!mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      return true;
    } catch (e) {
      _showError('Failed to delete product: $e');
      return false;
    }
  }

  Future<void> _showProductDetails(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          onEdit: _openProductForm,
          onDelete: _deleteProduct,
        ),
      ),
    );
  }

  // Compare calendar dates, not the hour/minute of the expiry timestamp.
  int _daysUntilExpiry(DateTime expirationDate) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final expiry = DateTime.utc(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    return expiry.difference(today).inDays;
  }

  bool _isExpired(Product product) =>
      _daysUntilExpiry(product.expirationDate) < 0;

  bool _isExpiringSoon(Product product) {
    final days = _daysUntilExpiry(product.expirationDate);
    return days >= 0 && days <= 7;
  }

  // The wireframe's expiry filter bottom sheet. Dates are inclusive.
  Future<void> _showExpiryFilters() async {
    int selected = expiryFilter == 4 || expiryFilter == 3 ? expiryFilter : 1;
    DateTime? start = customStartDate;
    DateTime? end = customEndDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          Future<void> pickDate(bool isStart) async {
            final now = DateUtils.dateOnly(DateTime.now());
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: (isStart ? start : end) ?? now,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null || !sheetContext.mounted) return;
            updateSheet(() {
              selected = 3;
              if (isStart) {
                start = DateUtils.dateOnly(picked);
              } else {
                end = DateUtils.dateOnly(picked);
              }
            });
          }

          String dateLabel(DateTime? date) => date == null
              ? 'Select date'
              : '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/${date.year}';

          final invalidRange =
              selected == 3 &&
              (start == null || end == null || start!.isAfter(end!));

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by expiration',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Choose a preset or custom date range.'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Next 7 days'),
                          selected: selected == 1,
                          onSelected: (_) => updateSheet(() => selected = 1),
                        ),
                        ChoiceChip(
                          label: const Text('Next 30 days'),
                          selected: selected == 4,
                          onSelected: (_) => updateSheet(() => selected = 4),
                        ),
                        ChoiceChip(
                          label: const Text('Custom range'),
                          selected: selected == 3,
                          onSelected: (_) => updateSheet(() => selected = 3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(true),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('FROM'),
                                Text(dateLabel(start)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(false),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('TO'),
                                Text(dateLabel(end)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selected == 3 &&
                        start != null &&
                        end != null &&
                        start!.isAfter(end!))
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Start date must be on or before end date.',
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: invalidRange
                            ? null
                            : () {
                                setState(() {
                                  expiryFilter = selected;
                                  if (selected == 3) {
                                    customStartDate = start;
                                    customEndDate = end;
                                  }
                                });
                                Navigator.pop(sheetContext);
                              },
                        child: const Text('Apply filters'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        searchText.toLowerCase(),
      );

      final days = _daysUntilExpiry(product.expirationDate);
      final expiryDate = DateUtils.dateOnly(product.expirationDate);
      final matchesExpiry =
          expiryFilter == 0 ||
          (expiryFilter == 1 && days >= 0 && days <= 7) ||
          (expiryFilter == 2 && days < 0) ||
          (expiryFilter == 4 && days >= 0 && days <= 30) ||
          (expiryFilter == 3 &&
              customStartDate != null &&
              customEndDate != null &&
              !expiryDate.isBefore(customStartDate!) &&
              !expiryDate.isAfter(customEndDate!));

      return matchesSearch && matchesExpiry;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage products and shelf life'),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _openProductForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: expiryFilter == 0,
                        onSelected: (_) {
                          setState(() {
                            expiryFilter = 0;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Next 7 days'),
                        selected: expiryFilter == 1,
                        onSelected: (_) {
                          setState(() {
                            expiryFilter = 1;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Expired'),
                        selected: expiryFilter == 2,
                        onSelected: (_) {
                          setState(() {
                            expiryFilter = 2;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Next 30 days'),
                        selected: expiryFilter == 4,
                        onSelected: (_) {
                          setState(() {
                            expiryFilter = 4;
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.filter_list, size: 18),
                        label: Text(
                          expiryFilter == 3 ? 'Custom dates' : 'Filters',
                        ),
                        onPressed: _showExpiryFilters,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text('${filteredProducts.length} products'),

                  const SizedBox(height: 12),

                  Expanded(
                    child: filteredProducts.isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];

                              return Card(
                                child: ListTile(
                                  onTap: () {
                                    _showProductDetails(product);
                                  },
                                  leading: const Icon(
                                    Icons.inventory_2_outlined,
                                  ),
                                  title: Text(product.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${product.category} · '
                                        '${product.stockQuantity} units · '
                                        '${product.sellingPrice.toStringAsFixed(2)} TL',
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _isExpired(product)
                                                    ? Colors.red.shade50
                                                    : _isExpiringSoon(product)
                                                    ? Colors.orange.shade50
                                                    : Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _isExpired(product)
                                                    ? 'Expired'
                                                    : _isExpiringSoon(product)
                                                    ? 'Expiring Soon (${_daysUntilExpiry(product.expirationDate)} days)'
                                                    : 'Fresh (${_daysUntilExpiry(product.expirationDate)} days)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _isExpired(product)
                                                      ? Colors.red.shade800
                                                      : _isExpiringSoon(product)
                                                      ? Colors.orange.shade900
                                                      : Colors.green.shade800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _deleteProduct(product);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// --------------------------------------------------
// ADD / EDIT PRODUCT DIALOG
// --------------------------------------------------

class _ProductFormDialog extends StatefulWidget {
  final Product? product;
  final List<String> categories;

  const _ProductFormDialog({this.product, required this.categories});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController costController;
  late final TextEditingController stockController;

  String? selectedCategory;
  String selectedSeason = 'All Year';
  late DateTime selectedDate;

  static const String addCategoryValue = '__add_category__';

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    nameController = TextEditingController(text: product?.name ?? '');

    priceController = TextEditingController(
      text: product?.sellingPrice.toString() ?? '',
    );

    costController = TextEditingController(
      text: product?.unitCost.toString() ?? '',
    );

    stockController = TextEditingController(
      text: product?.stockQuantity.toString() ?? '',
    );

    selectedCategory = product?.category;

    selectedSeason = product?.season ?? 'All Year';

    selectedDate =
        product?.expirationDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    costController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final newCategory = await showDialog<String>(
      context: context,
      builder: (context) => const _NewCategoryDialog(),
    );

    if (!mounted || newCategory == null) return;

    final name = newCategory.trim();

    if (name.isEmpty) return;

    final existingCategories = widget.categories.where(
      (category) => category.toLowerCase() == name.toLowerCase(),
    );

    final categoryName = existingCategories.isNotEmpty
        ? existingCategories.first
        : name;

    try {
      await DatabaseHelper.instance.insertCategory(categoryName);

      if (!mounted) return;

      setState(() {
        if (existingCategories.isEmpty) {
          widget.categories.add(categoryName);
        }

        selectedCategory = categoryName;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add category: $e')));
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  String? _validatePrice(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));

    if (number == null || !number.isFinite || number < 0) {
      return 'Enter a valid amount';
    }

    return null;
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final product = Product(
      id:
          widget.product?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      category: selectedCategory!,
      sellingPrice: double.parse(
        priceController.text.trim().replaceAll(',', '.'),
      ),
      unitCost: double.parse(costController.text.trim().replaceAll(',', '.')),
      stockQuantity: int.parse(stockController.text.trim()),
      expirationDate: selectedDate,
      season: selectedSeason,
    );

    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter product name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  key: ValueKey(selectedCategory),
                  initialValue: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select Category'),
                  items: [
                    ...widget.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: addCategoryValue,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text('Add Category'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == addCategoryValue) {
                      _addCategory();
                    } else {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                  validator: (_) {
                    if (selectedCategory == null || selectedCategory!.isEmpty) {
                      return 'Select a category';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (TL)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validatePrice,
                ),

                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Cost (TL)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validatePrice,
                ),

                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final quantity = int.tryParse((value ?? '').trim());

                    if (quantity == null || quantity < 0) {
                      return 'Enter a valid quantity';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                ListTile(
                  title: const Text('Expiration Date'),
                  subtitle: Text(
                    '${selectedDate.day}/'
                    '${selectedDate.month}/'
                    '${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),

                DropdownButtonFormField<String>(
                  initialValue: selectedSeason,
                  decoration: const InputDecoration(labelText: 'Season'),
                  items: ['All Year', 'Spring', 'Summer', 'Autumn', 'Winter']
                      .map((season) {
                        return DropdownMenuItem<String>(
                          value: season,
                          child: Text(season),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSeason = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveProduct, child: const Text('Save')),
      ],
    );
  }
}

// --------------------------------------------------
// ADD CATEGORY DIALOG
// --------------------------------------------------

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = controller.text.trim();

    if (name.isEmpty) return;

    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Category Name',
          hintText: 'e.g. Pet Food',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
