import 'product.dart';

class SampleProducts {
  static List<Product> get products {
    final today = DateTime.now();

    return [
      Product(
        id: 'P001',
        name: 'Milk 1 L',
        category: 'Dairy',
        sellingPrice: 49.90,
        unitCost: 35.00,
        stockQuantity: 25,
        expirationDate: today.add(const Duration(days: 3)),
        peakSeason: 'All year',
      ),

      Product(
        id: 'P002',
        name: 'Yogurt 500 g',
        category: 'Dairy',
        sellingPrice: 36.00,
        unitCost: 25.00,
        stockQuantity: 40,
        expirationDate: today.add(const Duration(days: 7)),
        peakSeason: 'All year',
      ),

      Product(
        id: 'P003',
        name: 'Ice Cream',
        category: 'Frozen Foods',
        sellingPrice: 80.00,
        unitCost: 45.00,
        stockQuantity: 30,
        expirationDate: today.add(const Duration(days: 30)),
        peakSeason: 'Summer',
      ),

      Product(
        id: 'P004',
        name: 'Hot Chocolate',
        category: 'Beverages',
        sellingPrice: 65.00,
        unitCost: 40.00,
        stockQuantity: 20,
        expirationDate: today.add(const Duration(days: 60)),
        peakSeason: 'Winter',
      ),

      Product(
        id: 'P005',
        name: 'Cheese 250 g',
        category: 'Dairy',
        sellingPrice: 89.90,
        unitCost: 60.00,
        stockQuantity: 15,
        expirationDate: today.add(const Duration(days: 1)),
        peakSeason: 'All year',
      ),
    ];
  }
}
