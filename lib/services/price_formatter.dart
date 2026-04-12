class PriceFormatter {
  /// Formats price in paise to a rupee string, e.g. 29900 -> '₹299'
  static String format(int paise) {
    final rupees = paise / 100;
    // Remove decimal if whole number
    if (paise % 100 == 0) {
      return '₹${rupees.toStringAsFixed(0)}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }
}
