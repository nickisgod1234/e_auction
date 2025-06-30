import 'package:intl/intl.dart';

class Format {
  // Safe number formatting that handles null values
  static String formatCurrency(dynamic value, {String symbol = '฿'}) {
    if (value == null) return '${symbol}0';
    
    // Convert to number if it's a string
    num? number;
    if (value is String) {
      number = num.tryParse(value);
    } else if (value is num) {
      number = value;
    }
    
    if (number == null) return '${symbol}0';
    
    return '${symbol}${NumberFormat('#,###').format(number)}';
  }

  // Safe number formatting without currency symbol
  static String formatNumber(dynamic value) {
    if (value == null) return '0';
    
    // Convert to number if it's a string
    num? number;
    if (value is String) {
      number = num.tryParse(value);
    } else if (value is num) {
      number = value;
    }
    
    if (number == null) return '0';
    
    return NumberFormat('#,###').format(number);
  }

  // Format price with fallback
  static String formatPrice(dynamic price, {dynamic fallback = 0}) {
    return formatCurrency(price ?? fallback);
  }
}
