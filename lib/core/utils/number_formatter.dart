/// Centralized number formatting utilities for the calculator app.
class NumberFormatter {
  NumberFormatter._();

  /// Formats a double with a max number of decimals, stripping trailing zeros,
  /// converting whole numbers to ints, and using scientific notation for large magnitudes.
  static String format(double value, [int maxDecimals = 2]) {
    if (value.isNaN) return 'Error';
    if (value.isInfinite) return value.isNegative ? '-Infinity' : 'Infinity';
    if (value.abs() >= 1000000) return value.toStringAsExponential(2);

    if (value == value.truncateToDouble() && maxDecimals <= 2) {
      return value.toInt().toString();
    }

    final fixed = value.toStringAsFixed(maxDecimals);
    return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  /// Formats currency with exactly 2 decimal places.
  static String formatCurrency(double value) {
    if (value.isNaN || value.isInfinite) return '0.00';
    return value.toStringAsFixed(2);
  }

  /// Adds thousands separator commas to a numeric string (e.g. "1234567.89" -> "1,234,567.89").
  static String addCommas(String raw) {
    if (raw == 'Error' || raw.isEmpty) return raw;
    final negative = raw.startsWith('-');
    final abs = negative ? raw.substring(1) : raw;
    final parts = abs.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    if (parts.length > 1) buf.write('.${parts[1]}');
    return negative ? '-${buf.toString()}' : buf.toString();
  }

  /// Formats spaced expression tokens by adding commas to recognized numbers.
  static String formatExpression(String raw) {
    if (raw.isEmpty) return '';
    return raw.split(' ').map((token) {
      return double.tryParse(token) != null ? addCommas(token) : token;
    }).join(' ');
  }
}
