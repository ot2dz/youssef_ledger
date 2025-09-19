/// Utilities for converting Arabic-Indic digits to European digits in date strings only
/// This ensures dates are displayed with 0-9 digits while preserving Arabic text

class DateDigitsUtils {
  // Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) to European mapping
  static const Map<String, String> _arabicIndicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  // Extended Arabic-Indic digits (۰۱۲۳۴۵۶۷۸۹) to European mapping
  static const Map<String, String> _extendedArabicIndicDigits = {
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  /// Converts Arabic-Indic and Extended Arabic-Indic digits to European digits (0-9)
  /// Preserves all other characters including Arabic text
  ///
  /// Example: "٢٠٢٥/٠١/١٥" → "2025/01/15"
  /// Example: "الجمعة ١٥ يناير ٢٠٢٥" → "الجمعة 15 يناير 2025"
  static String toEuropeanDigitsDateOnly(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      // Check Arabic-Indic digits first
      if (_arabicIndicDigits.containsKey(char)) {
        buffer.write(_arabicIndicDigits[char]);
      }
      // Check Extended Arabic-Indic digits
      else if (_extendedArabicIndicDigits.containsKey(char)) {
        buffer.write(_extendedArabicIndicDigits[char]);
      }
      // Keep all other characters unchanged (including Arabic text)
      else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  /// Checks if a string contains any Arabic-Indic or Extended Arabic-Indic digits
  /// Useful for debugging and testing
  static bool hasArabicIndicDigits(String input) {
    // Unicode ranges: ٠-٩ (\u0660-\u0669) and ۰-۹ (\u06F0-\u06F9)
    return RegExp(r'[\u0660-\u0669\u06F0-\u06F9]').hasMatch(input);
  }
}

/// Extension for convenient usage
extension DateDigitsStringExtension on String {
  /// Converts Arabic-Indic digits to European digits in date strings
  String toLatinDigitsDateOnly() =>
      DateDigitsUtils.toEuropeanDigitsDateOnly(this);

  /// Checks if string contains Arabic-Indic digits
  bool get hasArabicDigits => DateDigitsUtils.hasArabicIndicDigits(this);
}
