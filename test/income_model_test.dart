import 'package:flutter_test/flutter_test.dart';
import 'package:youssef_fabric_ledger/data/models/income.dart';
import 'package:youssef_fabric_ledger/core/enums.dart';

void main() {
  group('Income Model Tests', () {
    test('Income model should handle all valid source types', () {
      final validSources = [
        TransactionSource.cash,
        TransactionSource.drawer,
        TransactionSource.bank,
      ];

      for (final source in validSources) {
        final income = Income(
          date: DateTime.now(),
          amount: 100.0,
          source: source,
          note: 'Test income for ${source.name}',
          createdAt: DateTime.now(),
        );

        expect(income.source, equals(source));
        expect(income.amount, equals(100.0));
      }
    });

    test('Income toMap should preserve source field correctly', () {
      final income = Income(
        id: 1,
        date: DateTime.now(),
        amount: 150.0,
        source: TransactionSource.cash,
        note: 'Cash payment',
        createdAt: DateTime.now(),
      );

      final map = income.toMap();
      expect(map['source'], equals('cash'));
      expect(map['amount'], equals(150.0));
    });

    test('Income fromMap should reconstruct source field correctly', () {
      final map = {
        'id': 1,
        'date': DateTime.now().toIso8601String(),
        'amount': 200.0,
        'source': 'drawer',
        'note': 'Drawer payment',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final income = Income.fromMap(map);
      expect(income.source, equals('drawer'));
      expect(income.amount, equals(200.0));
    });
  });
}
