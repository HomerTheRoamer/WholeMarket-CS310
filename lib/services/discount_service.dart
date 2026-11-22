class DiscountService {
  // Discount based on expiration date
  static double expirationDiscount(int daysLeft) {
    if (daysLeft < 0) return 0;
    if (daysLeft <= 1) return 30;
    if (daysLeft <= 3) return 20;
    if (daysLeft <= 7) return 10;
    if (daysLeft <= 14) return 5;
    return 0;
  }

  // Determine the current season
  static String currentSeason(DateTime date) {
    final month = date.month;

    if (month >= 3 && month <= 5) {
      return 'Spring';
    }
    if (month >= 6 && month <= 8) {
      return 'Summer';
    }
    if (month >= 9 && month <= 11) {
      return 'Autumn';
    }
    return 'Winter';
  }

  // Discount based on product season

  static double seasonalDiscount(String peakSeason, String currentSeason) {
    final normalizedPeakSeason = peakSeason.trim().toLowerCase();
    final normalizedCurrentSeason = currentSeason.trim().toLowerCase();

    if (normalizedPeakSeason == 'all year') {
      return 0;
    }

    if (normalizedPeakSeason == normalizedCurrentSeason) {
      return 0;
    }

    return 10;
  }

  // Choose the higher discount
  static double recommendedDiscount({
    required int daysLeft,
    required String peakSeason,
    required DateTime today,
  }) {
    if (daysLeft < 0) {
      return 0;
    }

    final expiry = expirationDiscount(daysLeft);

    final seasonal = seasonalDiscount(peakSeason, currentSeason(today));

    return expiry > seasonal ? expiry : seasonal;
  }

  // Calculate discounted price
  static double discountedPrice(double sellingPrice, double discount) {
    return sellingPrice * (1 - discount / 100);
  }

  // Check whether discount covers unit cost
  static bool isAboveCost(
    double sellingPrice,
    double unitCost,
    double discount,
  ) {
    return discountedPrice(sellingPrice, discount) >= unitCost;
  }
}
