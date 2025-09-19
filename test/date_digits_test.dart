import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:youssef_fabric_ledger/core/utils/date_utils.dart';
import 'package:youssef_fabric_ledger/core/formatters/date_formatters.dart';

void main() {
  setUpAll(() async {
    // Initialize locale data for date formatting tests
    await initializeDateFormatting('ar', null);
  });

  group('Date Utils Tests', () {
    test('converts Arabic-Indic digits to European digits', () {
      // Test Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩)
      expect(
        DateDigitsUtils.toEuropeanDigitsDateOnly('٢٠٢٥/٠١/١٥'),
        equals('2025/01/15'),
      );
      expect(
        DateDigitsUtils.toEuropeanDigitsDateOnly('الجمعة ١٥ يناير ٢٠٢٥'),
        equals('الجمعة 15 يناير 2025'),
      );

      // Test Extended Arabic-Indic digits (۰۱۲۳۴۵۶۷۸۹)
      expect(
        DateDigitsUtils.toEuropeanDigitsDateOnly('۲۰۲۵/۰۱/۱۵'),
        equals('2025/01/15'),
      );

      // Test mixed content
      expect(
        DateDigitsUtils.toEuropeanDigitsDateOnly('التاريخ: ٢٠٢٥-١٢-٣١'),
        equals('التاريخ: 2025-12-31'),
      );

      // Test no change needed
      expect(
        DateDigitsUtils.toEuropeanDigitsDateOnly('2025/01/15'),
        equals('2025/01/15'),
      );
      expect(
        DateDigitsUtils.toEuropeanDigitsDateOnly('Friday 15 January 2025'),
        equals('Friday 15 January 2025'),
      );
    });

    test('detects Arabic-Indic digits', () {
      expect(DateDigitsUtils.hasArabicIndicDigits('٢٠٢٥'), isTrue);
      expect(DateDigitsUtils.hasArabicIndicDigits('۲۰۲۵'), isTrue);
      expect(DateDigitsUtils.hasArabicIndicDigits('2025'), isFalse);
      expect(DateDigitsUtils.hasArabicIndicDigits('يناير'), isFalse);
    });

    test('extension methods work correctly', () {
      expect('٢٠٢٥/٠١/١٥'.toLatinDigitsDateOnly(), equals('2025/01/15'));
      expect('٢٠٢٥'.hasArabicDigits, isTrue);
      expect('2025'.hasArabicDigits, isFalse);
    });
  });

  group('Date Formatters Tests', () {
    test('formats dates with European digits', () {
      final testDate = DateTime(2025, 1, 15); // Wednesday, January 15, 2025

      // Test formatters produce European digits
      final formatted = DateFormatters.formatFullDateArabic(testDate);
      expect(
        formatted.hasArabicDigits,
        isFalse,
        reason: 'Should not contain Arabic digits',
      );
      expect(formatted, contains('15'));
      expect(formatted, contains('2025'));

      final shortDate = DateFormatters.formatShortDate(testDate);
      expect(shortDate.hasArabicDigits, isFalse);
      expect(shortDate, equals('15/01/2025'));
    });

    test('extension methods work correctly', () {
      final testDate = DateTime(2025, 1, 15);

      final fullDate = testDate.toFullArabicDate();
      expect(fullDate.hasArabicDigits, isFalse);

      final shortDate = testDate.toShortDate();
      expect(shortDate, equals('15/01/2025'));
    });
  });
}
