// test/backup_system_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/services/data_aggregation_service.dart';
import 'package:youssef_fabric_ledger/services/encryption_service.dart';
import 'package:youssef_fabric_ledger/models/bank_transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  group('Backup System Integration Tests', () {
    late DatabaseHelper databaseHelper;
    late DataAggregationService dataAggregationService;

    setUpAll(() async {
      // إعداد sqflite_ffi للاختبارات
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // إعداد الخدمات
      databaseHelper = DatabaseHelper.instance;
      dataAggregationService = DataAggregationService(databaseHelper);
    });

    group('Data Aggregation Service Tests', () {
      test('should aggregate all data successfully', () async {
        final data = await dataAggregationService.aggregateAllData();

        expect(data, isNotNull);
        expect(data, isA<Map<String, dynamic>>());

        // التحقق من وجود جميع الجداول المطلوبة
        const expectedTables = [
          'parties',
          'debts',
          'expenses',
          'incomes',
          'cash_balance_log',
          'drawer_snapshots',
          'categories',
          'bank_transactions',
        ];

        for (final table in expectedTables) {
          expect(
            data.containsKey(table),
            isTrue,
            reason: 'Missing table: $table',
          );
          expect(
            data[table],
            isA<List>(),
            reason: 'Table $table should be a list',
          );
        }
      });

      test('should calculate table record counts', () async {
        final counts = await dataAggregationService.getTableRecordCounts();

        expect(counts, isNotNull);
        expect(counts, isA<Map<String, int>>());

        // التحقق من أن جميع العدادات أرقام صحيحة
        for (final count in counts.values) {
          expect(count, greaterThanOrEqualTo(0));
        }
      });

      test('should validate aggregated data', () async {
        final data = await dataAggregationService.aggregateAllData();
        final isValid = await dataAggregationService.validateAggregatedData(
          data,
        );

        expect(isValid, isTrue);
      });

      test('should estimate data size', () async {
        final size = await dataAggregationService.estimateDataSize();

        expect(size, greaterThanOrEqualTo(0));
      });

      test('should get specific table data', () async {
        const testTable = 'parties';
        final tableData = await dataAggregationService.getTableData(testTable);

        expect(tableData, isA<List<Map<String, dynamic>>>());
      });

      test('should handle invalid table name', () async {
        expect(
          () async =>
              await dataAggregationService.getTableData('invalid_table'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Encryption Service Tests', () {
      test('should encrypt and decrypt data correctly', () async {
        const password = 'testpassword123';
        const testData = {'test': 'data', 'number': 42};
        final jsonData = jsonEncode(testData);

        // تشفير البيانات
        final encryptedData = await EncryptionService.encrypt(
          jsonData,
          password,
        );
        expect(encryptedData, isNotNull);
        expect(encryptedData.isNotEmpty, isTrue);

        // فك التشفير
        final decryptedData = await EncryptionService.decrypt(
          encryptedData,
          password,
        );
        expect(decryptedData, equals(jsonData));

        // التحقق من البيانات المفككة
        final decodedData = jsonDecode(decryptedData);
        expect(decodedData, equals(testData));
      });

      test('should fail with wrong password', () async {
        const password = 'testpassword123';
        const wrongPassword = 'wrongpassword';
        const testData = 'test data';

        final encryptedData = await EncryptionService.encrypt(
          testData,
          password,
        );

        expect(
          () async =>
              await EncryptionService.decrypt(encryptedData, wrongPassword),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty data', () async {
        const password = 'testpassword123';
        const emptyData = '';

        final encryptedData = await EncryptionService.encrypt(
          emptyData,
          password,
        );
        final decryptedData = await EncryptionService.decrypt(
          encryptedData,
          password,
        );

        expect(decryptedData, equals(emptyData));
      });

      test('should generate different results for same input', () async {
        const password = 'testpassword123';
        const testData = 'test data';

        final encrypted1 = await EncryptionService.encrypt(testData, password);
        final encrypted2 = await EncryptionService.encrypt(testData, password);

        // يجب أن تكون النتائج مختلفة بسبب salt/iv مختلف
        expect(encrypted1, isNot(equals(encrypted2)));

        // لكن فك التشفير يجب أن يعطي نفس النتيجة
        final decrypted1 = await EncryptionService.decrypt(
          encrypted1,
          password,
        );
        final decrypted2 = await EncryptionService.decrypt(
          encrypted2,
          password,
        );
        expect(decrypted1, equals(testData));
        expect(decrypted2, equals(testData));
      });
    });

    group('Bank Transaction Integration Tests', () {
      test('should create and retrieve bank transactions', () async {
        // إنشاء معاملة مصرفية تجريبية
        final transaction = BankTransaction(
          type: BankTransactionType.credit,
          amount: 1000.0,
          accountNumber: 'ACC123456',
          bankName: 'Test Bank',
          description: 'Test transaction',
          transactionId: 'TXN001',
          date: DateTime.now(),
          balance: 1000.0,
          createdAt: DateTime.now(),
        );

        // حفظ المعاملة في قاعدة البيانات
        final transactionId = await databaseHelper.createBankTransaction(
          transaction.toMap(),
        );
        expect(transactionId, greaterThan(0));

        // استرجاع المعاملة
        final savedTransaction = await databaseHelper.getBankTransactionById(
          transactionId,
        );
        expect(savedTransaction, isNotNull);
        expect(savedTransaction!['accountNumber'], equals('ACC123456'));
        expect(savedTransaction['bankName'], equals('Test Bank'));
        expect(savedTransaction['amount'], equals(1000.0));
      });

      test('should include bank transactions in aggregated data', () async {
        // إنشاء معاملة مصرفية
        final transaction = BankTransaction(
          type: BankTransactionType.debit,
          amount: 500.0,
          accountNumber: 'ACC789',
          bankName: 'Another Bank',
          description: 'Another test transaction',
          transactionId: 'TXN002',
          date: DateTime.now(),
          balance: 500.0,
          createdAt: DateTime.now(),
        );

        await databaseHelper.createBankTransaction(transaction.toMap());

        // التحقق من تضمين المعاملات في البيانات المجمعة
        final data = await dataAggregationService.aggregateAllData();
        expect(data['bank_transactions'], isNotNull);

        final bankTransactions = data['bank_transactions'] as List;
        expect(bankTransactions.isNotEmpty, isTrue);

        // البحث عن المعاملة المحفوظة
        final savedTransaction = bankTransactions.firstWhere(
          (t) => t['accountNumber'] == 'ACC789',
          orElse: () => <String, dynamic>{},
        );
        expect(savedTransaction.isNotEmpty, isTrue);
        expect(savedTransaction['bankName'], equals('Another Bank'));
        expect(savedTransaction['amount'], equals(500.0));
      });

      test('should get bank transaction statistics', () async {
        // إنشاء عدة معاملات مصرفية
        final transactions = [
          BankTransaction(
            type: BankTransactionType.credit,
            amount: 1000.0,
            accountNumber: 'ACC111',
            bankName: 'Bank A',
            description: 'Credit 1',
            transactionId: 'TXN101',
            date: DateTime.now(),
            balance: 1000.0,
            createdAt: DateTime.now(),
          ),
          BankTransaction(
            type: BankTransactionType.credit,
            amount: 2000.0,
            accountNumber: 'ACC111',
            bankName: 'Bank A',
            description: 'Credit 2',
            transactionId: 'TXN102',
            date: DateTime.now(),
            balance: 3000.0,
            createdAt: DateTime.now(),
          ),
          BankTransaction(
            type: BankTransactionType.debit,
            amount: 500.0,
            accountNumber: 'ACC111',
            bankName: 'Bank A',
            description: 'Debit 1',
            transactionId: 'TXN103',
            date: DateTime.now(),
            balance: 2500.0,
            createdAt: DateTime.now(),
          ),
        ];

        // حفظ المعاملات
        for (final transaction in transactions) {
          await databaseHelper.createBankTransaction(transaction.toMap());
        }

        // الحصول على الإحصائيات
        final stats = await databaseHelper.getBankTransactionStats(
          accountNumber: 'ACC111',
          bankName: 'Bank A',
        );

        expect(stats, isNotNull);
        expect(stats['stats'], isA<List>());
        expect(stats['accountNumber'], equals('ACC111'));
        expect(stats['bankName'], equals('Bank A'));
      });

      test('should get bank accounts summary', () async {
        // إنشاء معاملات لحسابات مختلفة
        final transactions = [
          BankTransaction(
            type: BankTransactionType.credit,
            amount: 1000.0,
            accountNumber: 'ACC001',
            bankName: 'Bank X',
            description: 'Transaction 1',
            transactionId: 'TXN201',
            date: DateTime.now(),
            balance: 1000.0,
            createdAt: DateTime.now(),
          ),
          BankTransaction(
            type: BankTransactionType.credit,
            amount: 500.0,
            accountNumber: 'ACC002',
            bankName: 'Bank Y',
            description: 'Transaction 2',
            transactionId: 'TXN202',
            date: DateTime.now(),
            balance: 500.0,
            createdAt: DateTime.now(),
          ),
        ];

        for (final transaction in transactions) {
          await databaseHelper.createBankTransaction(transaction.toMap());
        }

        final accounts = await databaseHelper.getBankAccounts();
        expect(accounts, isA<List<Map<String, dynamic>>>());
        expect(accounts.isNotEmpty, isTrue);

        // التحقق من وجود حقول مطلوبة
        final firstAccount = accounts.first;
        expect(firstAccount.containsKey('accountNumber'), isTrue);
        expect(firstAccount.containsKey('bankName'), isTrue);
        expect(firstAccount.containsKey('transactionCount'), isTrue);
        expect(firstAccount.containsKey('balance'), isTrue);
      });

      test('should reconcile bank transactions', () async {
        // إنشاء معاملة مصرفية
        final transaction = BankTransaction(
          type: BankTransactionType.credit,
          amount: 750.0,
          accountNumber: 'ACC999',
          bankName: 'Reconcile Bank',
          description: 'Reconcile test',
          transactionId: 'TXN999',
          date: DateTime.now(),
          balance: 750.0,
          createdAt: DateTime.now(),
        );

        final transactionId = await databaseHelper.createBankTransaction(
          transaction.toMap(),
        );

        // تسوية المعاملة
        final result = await databaseHelper.reconcileBankTransaction(
          transactionId,
          true,
        );
        expect(result, equals(1)); // تم التحديث بنجاح

        // التحقق من حالة التسوية
        final reconciledTransaction = await databaseHelper
            .getBankTransactionById(transactionId);
        expect(reconciledTransaction!['isReconciled'], equals(1));
      });
    });

    group('Database Migration Tests', () {
      test('should handle bank_transactions table existence', () async {
        final db = await databaseHelper.database;

        // التحقق من وجود جدول bank_transactions
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='bank_transactions'",
        );

        expect(tables.isNotEmpty, isTrue);
      });

      test('should have correct bank_transactions schema', () async {
        final db = await databaseHelper.database;

        // الحصول على schema الجدول
        final schema = await db.rawQuery(
          "PRAGMA table_info(bank_transactions)",
        );

        expect(schema.isNotEmpty, isTrue);

        // التحقق من وجود الحقول المطلوبة
        final columnNames = schema
            .map((column) => column['name'] as String)
            .toList();

        const requiredColumns = [
          'id',
          'type',
          'amount',
          'accountNumber',
          'bankName',
          'transactionDate',
          'processedDate',
          'isReconciled',
        ];

        for (final column in requiredColumns) {
          expect(
            columnNames.contains(column),
            isTrue,
            reason: 'Missing column: $column',
          );
        }
      });
    });

    group('Performance Tests', () {
      test('should aggregate data efficiently', () async {
        final stopwatch = Stopwatch()..start();

        await dataAggregationService.aggregateAllData();

        stopwatch.stop();

        // يجب أن تكتمل العملية في وقت معقول (أقل من 5 ثوان)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('should handle large bank transactions efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // إنشاء عدة معاملات مصرفية
        for (int i = 0; i < 50; i++) {
          final transaction = BankTransaction(
            type: i % 2 == 0
                ? BankTransactionType.credit
                : BankTransactionType.debit,
            amount: (i + 1) * 100.0,
            accountNumber: 'ACC${i.toString().padLeft(3, '0')}',
            bankName: 'Performance Bank ${i % 3 + 1}',
            description: 'Performance test transaction $i',
            transactionId: 'TXN$i',
            date: DateTime.now().subtract(Duration(days: i)),
            balance: (i + 1) * 100.0,
            createdAt: DateTime.now().subtract(Duration(days: i)),
          );

          await databaseHelper.createBankTransaction(transaction.toMap());
        }

        stopwatch.stop();

        // يجب أن تكتمل إنشاء 50 معاملة في وقت معقول
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));

        // التحقق من إمكانية استرجاع البيانات بسرعة
        final retrieveStopwatch = Stopwatch()..start();
        final transactions = await databaseHelper.getBankTransactions(
          limit: 100,
        );
        retrieveStopwatch.stop();

        expect(transactions.length, greaterThanOrEqualTo(50));
        expect(retrieveStopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid encryption passwords gracefully', () async {
        const validPassword = 'correct_password';
        const invalidPassword = 'wrong_password';
        const testData = 'sensitive information';

        final encryptedData = await EncryptionService.encrypt(
          testData,
          validPassword,
        );

        // محاولة فك التشفير بكلمة مرور خاطئة
        try {
          await EncryptionService.decrypt(encryptedData, invalidPassword);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle database constraint violations', () async {
        // محاولة إنشاء معاملة مصرفية بنوع غير صحيح
        final invalidTransactionData = {
          'type': 'invalid_type', // نوع غير صحيح
          'amount': 100.0,
          'accountNumber': 'ACC123',
          'bankName': 'Test Bank',
          'transactionDate': DateTime.now().toIso8601String(),
          'processedDate': DateTime.now().toIso8601String(),
        };

        try {
          await databaseHelper.createBankTransaction(invalidTransactionData);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isNotNull);
        }
      });

      test('should handle empty bank transaction queries', () async {
        // البحث عن معاملات غير موجودة
        final transactions = await databaseHelper.getBankTransactions(
          accountNumber: 'NONEXISTENT_ACCOUNT',
        );

        expect(transactions, isEmpty);
      });
    });

    group('Security Tests', () {
      test('should encrypt data differently each time', () async {
        const password = 'security_test_password';
        const sensitiveData = 'confidential information';

        final encrypted1 = await EncryptionService.encrypt(
          sensitiveData,
          password,
        );
        final encrypted2 = await EncryptionService.encrypt(
          sensitiveData,
          password,
        );

        // يجب أن تكون النتائج مختلفة
        expect(encrypted1, isNot(equals(encrypted2)));

        // لكن فك التشفير يعطي نفس النتيجة
        final decrypted1 = await EncryptionService.decrypt(
          encrypted1,
          password,
        );
        final decrypted2 = await EncryptionService.decrypt(
          encrypted2,
          password,
        );

        expect(decrypted1, equals(sensitiveData));
        expect(decrypted2, equals(sensitiveData));
      });

      test('should not expose sensitive data in error messages', () async {
        const sensitivePassword = 'very_secret_password';
        const testData = 'test data';

        final encryptedData = await EncryptionService.encrypt(
          testData,
          sensitivePassword,
        );

        try {
          await EncryptionService.decrypt(encryptedData, 'wrong_password');
          fail('Should have thrown an exception');
        } catch (e) {
          final errorMessage = e.toString();

          // التحقق من عدم تسريب كلمة المرور في رسالة الخطأ
          expect(errorMessage.contains(sensitivePassword), isFalse);
          expect(errorMessage.contains('wrong_password'), isFalse);
        }
      });
    });
  });
}
