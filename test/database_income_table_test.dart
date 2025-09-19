import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/income.dart';

void main() {
  group('Database Income Table Tests', () {
    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    });

    test('Income table should be created without SQL syntax errors', () async {
      // This test verifies that the income table can be created successfully
      // without the inline comment syntax error

      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // Verify table exists by querying its structure
      final tableInfo = await db.rawQuery("PRAGMA table_info(income)");
      expect(tableInfo.isNotEmpty, true);

      // Verify source column has the correct CHECK constraint by testing valid values
      bool canInsertValidSource = true;
      try {
        await db.insert('income', {
          'date': DateTime.now().toIso8601String(),
          'amount': 100.0,
          'source': 'cash', // This should be allowed
          'note': 'Test income',
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        canInsertValidSource = false;
      }
      expect(
        canInsertValidSource,
        true,
        reason: 'Should allow valid source values',
      );

      // Verify CHECK constraint works by testing invalid value
      bool constraintWorks = false;
      try {
        await db.insert('income', {
          'date': DateTime.now().toIso8601String(),
          'amount': 100.0,
          'source': 'paypal', // This should be rejected
          'note': 'Test income',
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        constraintWorks = true; // Expected to fail
      }
      expect(
        constraintWorks,
        true,
        reason: 'CHECK constraint should reject invalid source values',
      );
    });

    test('All valid source types should be accepted', () async {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      final validSources = ['cash', 'drawer', 'bank'];

      for (final source in validSources) {
        bool success = true;
        try {
          await db.insert('income', {
            'date': DateTime.now().toIso8601String(),
            'amount': 100.0,
            'source': source,
            'note': 'Test income for $source',
            'createdAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          success = false;
        }
        expect(success, true, reason: 'Source "$source" should be accepted');
      }
    });
  });
}
