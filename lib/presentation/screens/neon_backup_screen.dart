import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/neon_database_service.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/debt_entry.dart';
import '../../data/models/expense.dart';
import '../../data/models/income.dart';
import '../../data/models/drawer_snapshot.dart';
import '../../models/cash_balance_log.dart';
import '../../logic/providers/finance_provider.dart';

class NeonBackupScreen extends StatefulWidget {
  const NeonBackupScreen({super.key});

  @override
  State<NeonBackupScreen> createState() => _NeonBackupScreenState();
}

class _NeonBackupScreenState extends State<NeonBackupScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  String? _currentUserEmail;
  List<Map<String, dynamic>> _backupsList = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadBackupsList();
  }

  Future<void> _loadUserInfo() async {
    final email = await AuthService.getCurrentUserEmail();
    setState(() {
      _currentUserEmail = email;
    });
  }

  Future<void> _loadBackupsList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId != null) {
        final response = await NeonDatabaseService.getUserBackups(userId);
        if (response['success'] == true) {
          final backups = response['backups'] as List<dynamic>? ?? [];
          setState(() {
            _backupsList = backups.cast<Map<String, dynamic>>();
          });
        } else {
          setState(() {
            _backupsList = [];
          });
        }
      } else {
        setState(() {
          _backupsList = [];
        });
      }
    } catch (e) {
      _setStatusMessage('خطأ في تحميل قائمة النسخ: $e', isError: true);
      setState(() {
        _backupsList = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setStatusMessage(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<Map<String, dynamic>> _exportAllData() async {
    try {
      // تصدير جميع البيانات من قاعدة البيانات المحلية
      final db = DatabaseHelper.instance;

      // الحصول على البيانات المهمة
      final parties = await db.getPersons() + await db.getVendors();
      final categories =
          await db.getCategories('expense') + await db.getCategories('income');

      // المعاملات والديون
      List<Map<String, dynamic>> allDebtEntries = [];
      for (final party in parties) {
        if (party.id != null) {
          final entries = await db.getDebtEntriesForParty(party.id!);
          allDebtEntries.addAll(entries.map((e) => e.toMap()).toList());
        }
      }

      // المصروفات والإيرادات
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, 1, 1); // آخر سنة من البيانات
      final endDate = now;

      final expenses = await db.getExpensesForDateRange(startDate, endDate);
      final income = await db.getIncomeForDateRange(startDate, endDate);

      // لقطات الدرج
      final drawerSnapshots = await db.getAllDrawerSnapshots();

      // سجل الرصيد النقدي
      final cashBalanceLogs = await db.getCashBalanceLogs();

      // المعاملات البنكية
      final bankTransactions = await db.getBankTransactions(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );

      // معلومات إضافية
      final totalCashBalance = await db.getSetting('totalCashBalance') ?? '0.0';

      return {
        'version': '2.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {
          // البيانات الأساسية
          'parties': parties.map((p) => p.toMap()).toList(),
          'categories': categories.map((c) => c.toMap()).toList(),

          // المعاملات المالية
          'debt_entries': allDebtEntries,
          'expenses': expenses.map((e) => e.toMap()).toList(),
          'income': income.map((i) => i.toMap()).toList(),

          // بيانات الدرج
          'drawer_snapshots': drawerSnapshots
              .map((d) => d.toMapForDb())
              .toList(),

          // السجلات
          'cash_balance_logs': cashBalanceLogs.map((c) => c.toMap()).toList(),
          'bank_transactions': bankTransactions,

          // الإعدادات
          'settings': {'totalCashBalance': totalCashBalance},
        },
      };
    } catch (e) {
      throw Exception('خطأ في تصدير البيانات: $e');
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري إنشاء النسخة الاحتياطية...';
    });

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم');
      }

      // تصدير البيانات
      final backupData = await _exportAllData();

      // إنشاء النسخة الاحتياطية في Neon
      final response = await NeonDatabaseService.createBackup(
        userId,
        'complete_backup',
        backupData,
        deviceInfo: 'Flutter App - ${DateTime.now().toString()}',
      );

      if (response['success'] == true) {
        _setStatusMessage('✅ تم إنشاء النسخة الاحتياطية بنجاح!');
        await _loadBackupsList(); // تحديث القائمة
      } else {
        throw Exception(
          response['message'] ?? 'فشل في إنشاء النسخة الاحتياطية',
        );
      }
    } catch (e) {
      _setStatusMessage('❌ خطأ في إنشاء النسخة الاحتياطية: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearExistingData() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // حذف البيانات من جميع الجداول
      await dbHelper.database.then((db) async {
        await db.transaction((txn) async {
          // حذف جميع البيانات (عدا الإعدادات التي ستتم استعادتها)
          await txn.delete('cash_balance_log');
          await txn.delete('income');
          await txn.delete('expenses');
          await txn.delete('debt_entries');
          await txn.delete('bank_transactions');
          await txn.delete('parties');
          await txn.delete('drawer_snapshots');
          await txn.delete('categories');
        });
      });

      print('✅ تم حذف البيانات الموجودة بنجاح');
    } catch (e) {
      print('❌ خطأ في حذف البيانات: $e');
      throw Exception('فشل في حذف البيانات الموجودة');
    }
  }

  Future<void> _importDataFromBackup(
    Map<String, dynamic> backupData, {
    bool mergeMode = false,
  }) async {
    try {
      print('🔄 بدء استيراد البيانات...');
      final db = DatabaseHelper.instance;
      final data = backupData['data'] ?? backupData;

      // خريطة لربط المعرفات القديمة والجديدة للأطراف
      Map<int, int> partyIdMap = {};

      // استيراد الأطراف أولاً لأن باقي البيانات تعتمد عليهم
      if (data['parties'] != null) {
        final parties = data['parties'] as List;
        for (var partyData in parties) {
          final partyMap = partyData as Map<String, dynamic>;
          final oldId = partyMap['id'] as int?;
          try {
            dynamic createdParty;
            if (partyMap['type'] == 'person') {
              createdParty = await db.createPerson(
                partyMap['name'],
                phone: partyMap['phone'],
              );
            } else {
              createdParty = await db.createVendor(
                partyMap['name'],
                phone: partyMap['phone'],
              );
            }
            // ربط المعرف القديم بالجديد
            if (oldId != null && createdParty.id != null) {
              partyIdMap[oldId] = createdParty.id!;
            }
          } catch (e) {
            // البحث عن الطرف الموجود وربط المعرفات
            try {
              final existingParties = partyMap['type'] == 'person'
                  ? await db.getPersons()
                  : await db.getVendors();
              final existingParty = existingParties.firstWhere(
                (p) => p.name == partyMap['name'],
              );
              if (oldId != null && existingParty.id != null) {
                partyIdMap[oldId] = existingParty.id!;
              }
            } catch (_) {
              print('⚠️ تعذر العثور على الطرف المطابق: ${partyMap['name']}');
            }
          }
        }
        print('✅ تم استيراد ${parties.length} طرف');
      }

      // استيراد الفئات
      if (data['categories'] != null) {
        final categories = data['categories'] as List;
        for (var categoryData in categories) {
          final categoryMap = categoryData as Map<String, dynamic>;
          try {
            final category = Category(
              name: categoryMap['name'],
              iconCodePoint:
                  categoryMap['iconCodePoint'] ?? Icons.category.codePoint,
              type: categoryMap['type'],
            );
            await db.createCategory(category);
          } catch (e) {
            print('⚠️ تم تخطي الفئة ${categoryMap['name']}: $e');
          }
        }
        print('✅ تم استيراد ${categories.length} فئة');
      }

      // استيراد المعاملات الديونية مع تحديث partyId
      if (data['debt_entries'] != null) {
        final debtEntries = data['debt_entries'] as List;
        for (var entryData in debtEntries) {
          final entryMap = Map<String, dynamic>.from(
            entryData as Map<String, dynamic>,
          );
          entryMap.remove('id');

          final oldPartyId = entryMap['partyId'] as int?;
          if (oldPartyId != null && partyIdMap.containsKey(oldPartyId)) {
            entryMap['partyId'] = partyIdMap[oldPartyId];
          }

          try {
            final debtEntry = DebtEntry.fromMap(entryMap);
            await db.createDebtEntry(debtEntry);
          } catch (e) {
            print('⚠️ خطأ في استيراد معاملة دين: $e');
          }
        }
        print('✅ تم استيراد ${debtEntries.length} معاملة دين');
      }

      // استيراد المصروفات مع منع التكرار
      if (data['expenses'] != null) {
        final expenses = data['expenses'] as List;
        int skippedExpenses = 0;

        for (var expenseData in expenses) {
          final expenseMap = Map<String, dynamic>.from(
            expenseData as Map<String, dynamic>,
          );
          expenseMap.remove('id');

          try {
            // فحص التكرار في وضع الدمج
            if (mergeMode) {
              final database = await db.database;
              final existingExpenses = await database.query(
                'expenses',
                where: 'amount = ? AND date = ? AND description = ?',
                whereArgs: [
                  expenseMap['amount'],
                  expenseMap['date'],
                  expenseMap['description'],
                ],
              );

              if (existingExpenses.isNotEmpty) {
                skippedExpenses++;
                continue;
              }
            }

            final expense = Expense.fromMap(expenseMap);
            await db.createExpense(expense);
          } catch (e) {
            print('⚠️ خطأ في استيراد مصروف: $e');
          }
        }

        if (mergeMode && skippedExpenses > 0) {
          print(
            '✅ تم استيراد ${expenses.length - skippedExpenses} مصروف (تم تخطي $skippedExpenses مكرر)',
          );
          setState(() {
            _statusMessage =
                'تم دمج ${expenses.length - skippedExpenses} مصروف جديد...';
          });
        } else {
          print('✅ تم استيراد ${expenses.length} مصروف');
        }
      }

      // استيراد الإيرادات مع منع التكرار
      if (data['income'] != null) {
        final incomes = data['income'] as List;
        int skippedIncomes = 0;

        for (var incomeData in incomes) {
          final incomeMap = Map<String, dynamic>.from(
            incomeData as Map<String, dynamic>,
          );
          incomeMap.remove('id');

          try {
            // فحص التكرار في وضع الدمج
            if (mergeMode) {
              final database = await db.database;
              final existingIncomes = await database.query(
                'income',
                where: 'amount = ? AND date = ? AND description = ?',
                whereArgs: [
                  incomeMap['amount'],
                  incomeMap['date'],
                  incomeMap['description'],
                ],
              );

              if (existingIncomes.isNotEmpty) {
                skippedIncomes++;
                continue;
              }
            }

            final income = Income.fromMap(incomeMap);
            await db.createIncome(income);
          } catch (e) {
            print('⚠️ خطأ في استيراد إيراد: $e');
          }
        }

        if (mergeMode && skippedIncomes > 0) {
          print(
            '✅ تم استيراد ${incomes.length - skippedIncomes} إيراد (تم تخطي $skippedIncomes مكرر)',
          );
          setState(() {
            _statusMessage =
                'تم دمج ${incomes.length - skippedIncomes} إيراد جديد...';
          });
        } else {
          print('✅ تم استيراد ${incomes.length} إيراد');
        }
      }

      // استيراد لقطات الدرج
      if (data['drawer_snapshots'] != null) {
        final snapshots = data['drawer_snapshots'] as List;
        for (var snapshotData in snapshots) {
          final snapshotMap = Map<String, dynamic>.from(
            snapshotData as Map<String, dynamic>,
          );
          snapshotMap.remove('id');
          try {
            final snapshot = DrawerSnapshot.fromMap(snapshotMap);
            await db.saveDrawerSnapshot(snapshot);
          } catch (e) {
            print('⚠️ خطأ في استيراد لقطة درج: $e');
          }
        }
        print('✅ تم استيراد ${snapshots.length} لقطة درج');
      }

      // استيراد سجلات الرصيد النقدي مع منع التكرار
      if (data['cash_balance_logs'] != null) {
        final logs = data['cash_balance_logs'] as List;
        int skippedLogs = 0;

        for (var logData in logs) {
          final logMap = Map<String, dynamic>.from(
            logData as Map<String, dynamic>,
          );
          logMap.remove('id');

          try {
            // فحص التكرار في وضع الدمج
            if (mergeMode) {
              final database = await db.database;
              final existingLogs = await database.query(
                'cash_balance_log',
                where: 'amount = ? AND changeType = ? AND timestamp = ?',
                whereArgs: [
                  logMap['amount'],
                  logMap['changeType'],
                  logMap['timestamp'],
                ],
              );

              if (existingLogs.isNotEmpty) {
                skippedLogs++;
                continue;
              }
            }

            final log = CashBalanceLog.fromMap(logMap);
            await db.insertCashBalanceLog(log);
          } catch (e) {
            print('⚠️ خطأ في استيراد سجل رصيد: $e');
          }
        }

        if (mergeMode && skippedLogs > 0) {
          print(
            '✅ تم استيراد ${logs.length - skippedLogs} سجل رصيد نقدي (تم تخطي $skippedLogs مكرر)',
          );
        } else {
          print('✅ تم استيراد ${logs.length} سجل رصيد نقدي');
        }
      }

      // استيراد المعاملات البنكية
      if (data['bank_transactions'] != null) {
        final transactions = data['bank_transactions'] as List;
        for (var transactionData in transactions) {
          final transactionMap = Map<String, dynamic>.from(
            transactionData as Map<String, dynamic>,
          );
          transactionMap.remove('id');
          try {
            await db.createBankTransaction(transactionMap);
          } catch (e) {
            print('⚠️ خطأ في استيراد معaملة بنكية: $e');
          }
        }
        print('✅ تم استيراد ${transactions.length} معاملة بنكية');
      }

      // استيراد الإعدادات (مهم جداً للرصيد النقدي)
      if (data['settings'] != null) {
        final settingsData = data['settings'];

        // التحقق من نوع البيانات - قد تكون List أو Map
        if (settingsData is List) {
          // إذا كانت List (تنسيق قديم)
          final settings = settingsData;
          for (var settingData in settings) {
            final settingMap = settingData as Map<String, dynamic>;
            try {
              await db.saveSetting(
                settingMap['key'] as String,
                settingMap['value'] as String,
              );
              if (settingMap['key'] == 'totalCashBalance') {
                print('💰 تم استعادة الرصيد النقدي: ${settingMap['value']}');
              }
            } catch (e) {
              print('⚠️ خطأ في استيراد إعداد ${settingMap['key']}: $e');
            }
          }
          print('✅ تم استيراد ${settings.length} إعداد');
        } else if (settingsData is Map<String, dynamic>) {
          // إذا كانت Map (تنسيق جديد)
          int settingsCount = 0;
          for (var entry in settingsData.entries) {
            try {
              await db.saveSetting(entry.key, entry.value.toString());
              if (entry.key == 'totalCashBalance') {
                print('💰 تم استعادة الرصيد النقدي: ${entry.value}');
              }
              settingsCount++;
            } catch (e) {
              print('⚠️ خطأ في استيراد إعداد ${entry.key}: $e');
            }
          }
          print('✅ تم استيراد $settingsCount إعداد');
        }
      }
      if (mergeMode) {
        print('🎉 تم دمج البيانات الجديدة مع الموجودة بنجاح!');
      } else {
        print('🎉 تم استيراد البيانات الكاملة بنجاح!');
      }
    } catch (e) {
      print('❌ خطأ في استيراد البيانات: $e');
      rethrow;
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    // حوار متقدم لخيارات الاستعادة
    final restoreOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خيارات الاستعادة'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختر نوع الاستعادة:'),
            SizedBox(height: 16),
            Text(
              '• الاستعادة الكاملة: حذف جميع البيانات الحالية واستبدالها',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '• الاستعادة المضافة: إضافة البيانات للموجود حالياً (قد يسبب تكرار)',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('merge'),
            child: const Text('استعادة مضافة'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('full'),
            child: const Text('استعادة كاملة'),
          ),
        ],
      ),
    );

    if (restoreOption == null || restoreOption == 'cancel') return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري استعادة النسخة الاحتياطية...';
    });

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم');
      }

      // الحصول على البيانات الكاملة للنسخة الاحتياطية
      final response = await NeonDatabaseService.getLatestBackup(userId);

      if (response['success'] == true && response['data'] != null) {
        final backupData = response['data'] as Map<String, dynamic>;

        // تنفيذ الحذف إذا كانت استعادة كاملة
        if (restoreOption == 'full') {
          setState(() {
            _statusMessage = 'جاري حذف البيانات الموجودة...';
          });
          await _clearExistingData();
        }

        setState(() {
          if (restoreOption == 'full') {
            _statusMessage = 'جاري استيراد البيانات (استعادة كاملة)...';
          } else {
            _statusMessage = 'جاري استيراد البيانات (دمج مع الموجود)...';
          }
        });
        await _importDataFromBackup(
          backupData,
          mergeMode: restoreOption == 'merge',
        );

        // تحديث FinanceProvider بعد استعادة البيانات
        if (mounted) {
          final financeProvider = Provider.of<FinanceProvider>(
            context,
            listen: false,
          );
          await financeProvider.loadInitialData();
          await financeProvider.refreshTodayData();
        }

        if (restoreOption == 'full') {
          _setStatusMessage(
            '✅ تم استبدال جميع البيانات بالنسخة الاحتياطية بنجاح!',
          );
        } else {
          _setStatusMessage('✅ تم دمج البيانات الجديدة مع الموجودة بنجاح!');
        }
      } else {
        throw Exception('فشل في استرجاع بيانات النسخة الاحتياطية');
      }
    } catch (e) {
      _setStatusMessage(
        '❌ خطأ في استعادة النسخة الاحتياطية: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'النسخ الاحتياطي السحابي',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات المستخدم
            _buildUserInfoCard(),
            const SizedBox(height: 20),

            // رسالة الحالة
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('❌')
                      ? Colors.red[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusMessage.contains('❌')
                        ? Colors.red[300]!
                        : Colors.green[300]!,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('❌')
                        ? Colors.red[800]
                        : Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // أزرار العمليات
            _buildActionButtons(),
            const SizedBox(height: 30),

            // قائمة النسخ الاحتياطية
            _buildBackupsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المستخدم الحالي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUserEmail ?? 'غير متصل',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _currentUserEmail != null
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentUserEmail != null ? 'متصل' : 'غير متصل',
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentUserEmail != null
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud, color: Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بياناتك محفوظة بأمان في السحاب مع تشفير كامل',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading || _currentUserEmail == null
                ? null
                : _createBackup,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(_isLoading ? 'جاري الحفظ...' : 'إنشاء نسخة احتياطية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _loadBackupsList,
          icon: const Icon(Icons.refresh),
          label: const Text('تحديث'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  'النسخ الاحتياطية المحفوظة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_backupsList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد نسخ احتياطية',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'قم بإنشاء أول نسخة احتياطية لحفظ بياناتك',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ...(_backupsList
                  .map((backup) => _buildBackupItem(backup))
                  .toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(Map<String, dynamic> backup) {
    // التحقق من وجود البيانات المطلوبة
    final createdAtStr =
        (backup['created_at'] ?? backup['backup_date']) as String?;
    DateTime createdAt;

    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr);
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    final size = (backup['backup_size'] as num?)?.toInt() ?? 0;
    final backupType = backup['backup_type'] as String? ?? 'نسخة كاملة';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.backup, color: Colors.green[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backupType,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'تم الإنشاء: ${_formatDate(createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (size > 0)
                  Text(
                    'الحجم: ${_formatSize(size)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _restoreBackup(backup),
            icon: const Icon(Icons.cloud_download, size: 16),
            label: const Text('استعادة', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
