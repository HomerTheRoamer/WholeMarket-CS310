class Product {
  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final double unitCost;
  final int stockQuantity;
  final DateTime expirationDate;
  final String peakSeason;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.unitCost,
    required this.stockQuantity,
    required this.expirationDate,
    required this.peakSeason,
  });

  // Number of days until the product expires
  int get daysUntilExpiration {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiration = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );

    return expiration.difference(today).inDays;
  }

  // Whether the product has already expired
  bool get isExpired {
    return daysUntilExpiration < 0;
  }
}
