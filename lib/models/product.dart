
class Product {
  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final double unitCost;
  final int stockQuantity;
  final DateTime expirationDate;
  final String season;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.unitCost,
    required this.stockQuantity,
    required this.expirationDate,
    this.season = 'All Year',
  });

  int get daysUntilExpiry {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final expiry = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );

    return expiry.difference(currentDate).inDays;
  }

  bool get isExpiringSoon =>
      daysUntilExpiry >= 0 && daysUntilExpiry <= 7;

  bool get isExpired => daysUntilExpiry < 0;
}
