import 'package:intl/intl.dart';
import '../utils/date_utils.dart';

/// Date formatters that ensure European digits (0-9) are displayed
/// while preserving Arabic language text in dates

class DateFormatters {
  /// Formats date with Arabic language but European digits
  ///
  /// Example: DateTime(2025, 1, 15) → "الأربعاء 15 يناير 2025" (not "الأربعاء ١٥ يناير ٢٠٢٥")
  static String formatDateWithLatinDigits(
    DateTime date, {
    String pattern = 'yMMMMEEEEd',
    String locale = 'ar',
  }) {
    final formatter = DateFormat(pattern, locale);
    final formattedDate = formatter.format(date);
    return formattedDate.toLatinDigitsDateOnly();
  }

  /// Formats date as full Arabic date with European digits
  /// Example: "الأربعاء 15 يناير 2025"
  static String formatFullDateArabic(DateTime date) {
    return formatDateWithLatinDigits(date, pattern: 'yMMMMEEEEd', locale: 'ar');
  }

  /// Formats date as short date with European digits
  /// Example: "15/01/2025"
  static String formatShortDate(DateTime date) {
    return formatDateWithLatinDigits(date, pattern: 'dd/MM/yyyy', locale: 'ar');
  }

  /// Formats date as medium date with European digits
  /// Example: "15 يناير 2025"
  static String formatMediumDate(DateTime date) {
    return formatDateWithLatinDigits(
      date,
      pattern: 'dd MMMM yyyy',
      locale: 'ar',
    );
  }

  /// Formats custom date pattern with European digits
  static String formatCustomDate(
    DateTime date,
    String pattern, {
    String locale = 'ar',
  }) {
    return formatDateWithLatinDigits(date, pattern: pattern, locale: locale);
  }
}

/// Extension for convenient DateTime formatting
extension DateTimeFormatting on DateTime {
  /// Formats this DateTime with Arabic text but European digits
  String toArabicWithLatinDigits({String pattern = 'yMMMMEEEEd'}) {
    return DateFormatters.formatDateWithLatinDigits(this, pattern: pattern);
  }

  /// Formats as full Arabic date: "الأربعاء 15 يناير 2025"
  String toFullArabicDate() => DateFormatters.formatFullDateArabic(this);

  /// Formats as short date: "15/01/2025"
  String toShortDate() => DateFormatters.formatShortDate(this);

  /// Formats as medium date: "15 يناير 2025"
  String toMediumDate() => DateFormatters.formatMediumDate(this);
}
