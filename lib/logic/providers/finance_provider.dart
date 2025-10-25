import 'package:flutter/foundation.dart';
import 'package:youssef_fabric_ledger/core/enums.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/drawer_snapshot.dart';
import 'package:youssef_fabric_ledger/data/models/expense.dart';
import 'package:youssef_fabric_ledger/data/models/income.dart';
import 'package:youssef_fabric_ledger/data/models/debt_entry.dart';
import 'package:youssef_fabric_ledger/logic/providers/date_provider.dart';
import 'package:youssef_fabric_ledger/models/cash_balance_log.dart';

enum DrawerStatus {
  complete,
  pendingEnd,
  missingStart,
  crossDateComplete, // حسابات متقاطعة مكتملة
}

class FinanceProvider with ChangeNotifier {
  final DatabaseHelper dbHelper;
  final DateProvider dateProvider;

  // --- الحالة المالية ---
  double _totalCashBalance = 0.0;
  double get totalCashBalance => _totalCashBalance;

  // ... (rest of the properties are the same)
  double _grossProfit = 0.0; // = ربح اليوم (20%)
  double get grossProfit => _grossProfit;
  double get dailyProfit => _grossProfit;
  double _totalExpenses = 0.0; // مصروفات اليوم
  double get totalExpenses => _totalExpenses;

  double _totalIncome = 0.0; // دخل اليوم
  double get totalIncome => _totalIncome;

  double _netProfit = 0.0; // صافي ربح اليوم = ربح اليوم - مصروفات اليوم
  double get netProfit => _netProfit;

  DrawerStatus _drawerStatus = DrawerStatus.pendingEnd;
  DrawerStatus get drawerStatus => _drawerStatus;

  // --- أرصدة الدرج لليوم ---
  double? _startOfDayBalance;
  double? get startOfDayBalance => _startOfDayBalance;

  double? _endOfDayBalance;
  double? get endOfDayBalance => _endOfDayBalance;

  // --- التواريخ الفعالة للحسابات المتقاطعة ---
  DateTime? _effectiveStartDate;
  DateTime? get effectiveStartDate => _effectiveStartDate;

  DateTime? _effectiveEndDate;
  DateTime? get effectiveEndDate => _effectiveEndDate;

  // --- مؤشر إذا كانت البيانات من أيام مختلفة ---
  bool get isCrossDateCalculation =>
      _effectiveStartDate != null &&
      _effectiveEndDate != null &&
      _effectiveStartDate!.day != _effectiveEndDate!.day;

  double _calculatedTurnover = 0.0;
  double get calculatedTurnover => _calculatedTurnover;

  double _profitPercent = 0.20; // 20%

  Map<String, double> get drawerFinalState {
    final opening = _startOfDayBalance ?? 0.0;
    final closing = _endOfDayBalance ?? 0.0;
    // This calculation might need adjustment based on business logic
    // For now, it's a simple difference.
    final difference = closing - opening;

    return {
      'openingBalance': opening,
      'closingBalance': closing,
      'difference': difference,
    };
  }

  // --- حالة الدرج المحدثة ---
  Map<String, DrawerSnapshot?> _drawerSnapshots = {'start': null, 'end': null};
  Map<String, DrawerSnapshot?> get drawerSnapshots => _drawerSnapshots;

  // إحصائيات شهرية وسنوية
  double _monthlyIncome = 0.0;
  double get monthlyIncome => _monthlyIncome;

  double _monthlyExpenses = 0.0;
  double get monthlyExpenses => _monthlyExpenses;

  double _monthlyNetProfit = 0.0;
  double get monthlyNetProfit => _monthlyNetProfit;

  FinanceProvider({required this.dbHelper, required this.dateProvider}) {
    // Listen to date changes and refetch data
    dateProvider.addListener(_onDateChanged);
    loadInitialData();
  }

  void _onDateChanged() {
    fetchFinancialDataForSelectedDate();
  }

  @override
  void dispose() {
    dateProvider.removeListener(_onDateChanged);
    super.dispose();
  }

  Future<void> loadInitialData() async {
    final savedBalance = await dbHelper.getSetting('totalCashBalance');
    _totalCashBalance = double.tryParse(savedBalance ?? '0.0') ?? 0.0;
    await fetchFinancialDataForSelectedDate();
  }

  /// Fetches financial data for the date selected in DateProvider.
  Future<void> fetchFinancialDataForSelectedDate() async {
    // Reload total cash balance from database
    final savedBalance = await dbHelper.getSetting('totalCashBalance');
    _totalCashBalance = double.tryParse(savedBalance ?? '0.0') ?? 0.0;

    final selectedDate = dateProvider.selectedDate;

    // 1. Fetch drawer snapshots for current date
    final startSnapshot = await dbHelper.getSnapshotForDate(
      selectedDate,
      SnapshotType.start,
    );
    final endSnapshot = await dbHelper.getSnapshotForDate(
      selectedDate,
      SnapshotType.end,
    );

    // 2. Smart balance determination with new logic
    double? startAmount = startSnapshot?.cashAmount;
    double? endAmount = endSnapshot?.cashAmount;
    DateTime? effectiveStartDate = startSnapshot?.date;
    DateTime? effectiveEndDate = endSnapshot?.date;

    // If no start balance for today, use last start balance before last closure
    if (startAmount == null) {
      final lastStartBeforeClosure = await dbHelper
          .getLastStartBalanceBeforeLastClosure();
      if (lastStartBeforeClosure != null) {
        startAmount = lastStartBeforeClosure.cashAmount;
        effectiveStartDate = lastStartBeforeClosure.date;
      }
    }

    // If no end balance for today, find the earliest end snapshot after the effective start date
    if (endAmount == null && effectiveStartDate != null) {
      final nextEndSnapshot = await dbHelper.getEarliestEndSnapshotAfter(
        effectiveStartDate,
      );
      if (nextEndSnapshot != null) {
        endAmount = nextEndSnapshot.cashAmount;
        effectiveEndDate = nextEndSnapshot.date;
      }
    }

    _startOfDayBalance = startAmount;
    _endOfDayBalance = endAmount;
    _effectiveStartDate = effectiveStartDate;
    _effectiveEndDate = effectiveEndDate;

    // 3. Enhanced drawer status with cross-date support
    if (_startOfDayBalance == null) {
      _drawerStatus = DrawerStatus.missingStart;
    } else if (_endOfDayBalance == null) {
      _drawerStatus = DrawerStatus.pendingEnd;
    } else {
      // Check if we have a valid pair
      if (isCrossDateCalculation) {
        _drawerStatus = DrawerStatus.crossDateComplete;
      } else {
        _drawerStatus = DrawerStatus.complete;
      }
    }

    debugPrint('[FINANCE] Enhanced drawer calculation:');
    debugPrint('[FINANCE] Selected date: $selectedDate');
    debugPrint('[FINANCE] Effective start date: $_effectiveStartDate');
    debugPrint('[FINANCE] Effective end date: $_effectiveEndDate');
    debugPrint('[FINANCE] Cross-date calculation: $isCrossDateCalculation');
    debugPrint('[FINANCE] Start balance: $_startOfDayBalance');
    debugPrint('[FINANCE] End balance: $_endOfDayBalance');
    debugPrint('[FINANCE] Drawer status: $_drawerStatus');

    // 4. Calculate turnover with enhanced cross-date support
    _calculatedTurnover = 0.0;
    if ((_drawerStatus == DrawerStatus.complete ||
            _drawerStatus == DrawerStatus.crossDateComplete) &&
        _effectiveStartDate != null &&
        _effectiveEndDate != null) {
      // Calculate expenses for the period between start and end dates
      final drawerOutflows = await dbHelper.getDrawerExpensesForDateRange(
        _effectiveStartDate!,
        _effectiveEndDate!,
      );

      // Pure cash difference (may span multiple days)
      _calculatedTurnover =
          (_endOfDayBalance! - _startOfDayBalance!) + drawerOutflows;

      debugPrint('[FINANCE] Enhanced drawer calculation:');
      debugPrint(
        '[FINANCE] Period: $_effectiveStartDate to $_effectiveEndDate',
      );
      debugPrint('[FINANCE] Start balance: $_startOfDayBalance');
      debugPrint('[FINANCE] End balance: $_endOfDayBalance');
      debugPrint('[FINANCE] Drawer outflows (period): $drawerOutflows');
      debugPrint(
        '[FINANCE] Calculated turnover (enhanced): $_calculatedTurnover',
      );
    }

    // 5. Calculate final totals
    final manualIncomes = await dbHelper.getIncomeForDate(selectedDate);
    final manualIncomesTotal = manualIncomes.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    _totalIncome = _calculatedTurnover + manualIncomesTotal;

    debugPrint('[FINANCE] ═══════════════════════════════════════');
    debugPrint('[FINANCE] Final income calculation:');
    debugPrint('[FINANCE] Calculated turnover: $_calculatedTurnover');
    debugPrint('[FINANCE] Manual incomes count: ${manualIncomes.length}');
    debugPrint('[FINANCE] Manual incomes total: $manualIncomesTotal');
    debugPrint('[FINANCE] Total income: $_totalIncome');

    final allExpenses = await dbHelper.getExpensesForDate(selectedDate);
    _totalExpenses = allExpenses.fold(0.0, (sum, item) => sum + item.amount);

    debugPrint('[FINANCE] Expenses count: ${allExpenses.length}');
    debugPrint('[FINANCE] Total expenses: $_totalExpenses');

    _grossProfit = _totalIncome * _profitPercent;
    _netProfit = _grossProfit - _totalExpenses;

    debugPrint(
      '[FINANCE] Gross profit (${(_profitPercent * 100).toStringAsFixed(0)}%): $_grossProfit',
    );
    debugPrint('[FINANCE] Net profit: $_netProfit');
    debugPrint('[FINANCE] ═══════════════════════════════════════');

    notifyListeners();
  }

  /// Refreshes data for the current day.
  Future<void> refreshTodayData() async {
    // This method now simply ensures the date is current and fetches data.
    // The actual date change is handled by DateProvider.
    if (!dateProvider.isSameDay(dateProvider.selectedDate, DateTime.now())) {
      dateProvider.selectDate(DateTime.now());
    } else {
      await fetchFinancialDataForSelectedDate();
    }
    // Force UI refresh after data refresh
    notifyListeners();
  }

  Future<void> updateTotalCashBalance(double newBalance) async {
    _totalCashBalance = newBalance;
    await dbHelper.saveSetting('totalCashBalance', newBalance.toString());
    notifyListeners();
  }

  /// Helper method to log cash balance changes and update the balance
  Future<void> _logAndUpdateCashBalance({
    required double oldBalance,
    required double newBalance,
    required CashBalanceChangeType changeType,
    required String reason,
    String? details,
  }) async {
    final now = DateTime.now();
    final log = CashBalanceLog(
      timestamp: now,
      changeType: changeType,
      oldBalance: oldBalance,
      newBalance: newBalance,
      amount: (newBalance - oldBalance).abs(),
      reason: reason,
      details: details,
      createdAt: now,
    );

    // Save the log entry
    await dbHelper.insertCashBalanceLog(log);

    // Update the balance
    _totalCashBalance = newBalance;
    await dbHelper.saveSetting('totalCashBalance', newBalance.toString());
    notifyListeners();
  }

  /// Public method for manual cash balance updates with logging
  Future<void> updateTotalCashBalanceWithLog({
    required double newBalance,
    required String reason,
    String? details,
  }) async {
    final oldBalance = _totalCashBalance;

    await _logAndUpdateCashBalance(
      oldBalance: oldBalance,
      newBalance: newBalance,
      changeType: CashBalanceChangeType.manualEdit,
      reason: reason,
      details: details,
    );
  }

  Future<void> saveDrawerSnapshot({
    required DateTime date,
    required SnapshotType type,
    required double amount,
    String? note,
  }) async {
    final snapshot = DrawerSnapshot(
      date: date,
      type: type,
      cashAmount: amount,
      note: note,
      createdAt: DateTime.now(),
    );
    final savedSnapshot = await dbHelper.saveDrawerSnapshot(snapshot);
    _drawerSnapshots[type.name] = savedSnapshot;

    // If this is an end snapshot (closing the day), add daily income to total cash balance
    if (type == SnapshotType.end) {
      await _handleDayClosing(date);
    }

    if (dateProvider.isSameDay(date, dateProvider.selectedDate)) {
      await fetchFinancialDataForSelectedDate();
    } else {
      notifyListeners();
    }
  }

  /// Adds income and updates total cash balance if it's a cash income
  Future<Income> addIncome(Income income) async {
    // Save the income in the database
    final savedIncome = await dbHelper.createIncome(income);

    // If it's cash income, update the total cash balance immediately
    if (income.source == TransactionSource.cash && income.amount > 0) {
      final oldBalance = _totalCashBalance;
      final newBalance = oldBalance + income.amount;

      await _logAndUpdateCashBalance(
        oldBalance: oldBalance,
        newBalance: newBalance,
        changeType: CashBalanceChangeType.cashIncome,
        reason: 'دخل نقدي: ${income.note}',
        details: 'مبلغ: ${income.amount}',
      );

      debugPrint(
        '[FINANCE] Cash income added: ${income.amount}, New total balance: $newBalance',
      );
    }

    // Refresh the data if it's for the selected date
    if (dateProvider.isSameDay(income.date, dateProvider.selectedDate)) {
      await fetchFinancialDataForSelectedDate();
    } else {
      notifyListeners();
    }

    return savedIncome;
  }

  /// Handles the closing of a day by adding daily income to total cash balance
  Future<void> _handleDayClosing(DateTime closingDate) async {
    // Calculate the daily income for the closing date
    final dailyIncome = await _calculateDailyIncome(closingDate);

    if (dailyIncome > 0) {
      final oldBalance = _totalCashBalance;
      final newBalance = oldBalance + dailyIncome;

      await _logAndUpdateCashBalance(
        oldBalance: oldBalance,
        newBalance: newBalance,
        changeType: CashBalanceChangeType.dayClosing,
        reason: 'إقفال يوم ${closingDate.toIso8601String().substring(0, 10)}',
        details: 'ربح يومي: $dailyIncome',
      );

      debugPrint(
        '[FINANCE] Day closed for $closingDate: Daily income $dailyIncome added, New balance: $newBalance',
      );
    }
  }

  /// Calculates total daily income (drawer turnover + manual income) for a specific date
  Future<double> _calculateDailyIncome(DateTime date) async {
    // Get start snapshot for the date
    final startSnapshot = await dbHelper.getSnapshotForDate(
      date,
      SnapshotType.start,
    );
    final endSnapshot = await dbHelper.getSnapshotForDate(
      date,
      SnapshotType.end,
    );

    double drawerTurnover = 0.0;

    if (startSnapshot != null && endSnapshot != null) {
      // Get drawer expenses for the date
      final drawerExpenses = await dbHelper.getDrawerExpensesForDate(date);

      // Calculate drawer turnover
      drawerTurnover =
          (endSnapshot.cashAmount - startSnapshot.cashAmount) + drawerExpenses;
    } else if (endSnapshot != null) {
      // If no start snapshot for today, use the new logic
      final lastStartBeforeClosure = await dbHelper
          .getLastStartBalanceBeforeLastClosure();
      if (lastStartBeforeClosure != null) {
        final drawerExpenses = await dbHelper.getDrawerExpensesForDate(date);
        drawerTurnover =
            (endSnapshot.cashAmount - lastStartBeforeClosure.cashAmount) +
            drawerExpenses;
      }
    }

    // Get manual income for the date
    final manualIncomes = await dbHelper.getIncomeForDate(date);
    final manualIncomeTotal = manualIncomes.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final totalDailyIncome = drawerTurnover + manualIncomeTotal;

    debugPrint('[FINANCE] Daily income calculation for $date:');
    debugPrint('[FINANCE] Drawer turnover: $drawerTurnover');
    debugPrint('[FINANCE] Manual income: $manualIncomeTotal');
    debugPrint('[FINANCE] Total daily income: $totalDailyIncome');

    return totalDailyIncome;
  }

  Future<void> addOrUpdateExpense(Expense expense) async {
    // Store old expense amount for update scenarios
    Expense? oldExpense;
    if (expense.id != null) {
      // For updates, get the old expense to calculate the difference
      oldExpense = await dbHelper.getExpenseById(expense.id!);
    }

    if (expense.id == null) {
      await dbHelper.createExpense(expense);

      // For new cash expenses, deduct from total cash balance
      if (expense.source == TransactionSource.cash) {
        final oldBalance = _totalCashBalance;
        final newBalance = oldBalance - expense.amount;

        await _logAndUpdateCashBalance(
          oldBalance: oldBalance,
          newBalance: newBalance,
          changeType: CashBalanceChangeType.cashExpense,
          reason: 'مصروف نقدي: ${expense.note ?? 'بدون ملاحظة'}',
          details: 'مبلغ: ${expense.amount}',
        );

        debugPrint(
          '[FINANCE] Cash expense added: ${expense.amount}, New balance: $newBalance',
        );
      }
    } else {
      await dbHelper.updateExpense(expense);

      // For cash expense updates, adjust the balance
      if (expense.source == TransactionSource.cash && oldExpense != null) {
        if (oldExpense.source == TransactionSource.cash) {
          // Both old and new are cash: adjust by difference
          final difference = expense.amount - oldExpense.amount;
          final oldBalance = _totalCashBalance;
          final newBalance = oldBalance - difference;

          await _logAndUpdateCashBalance(
            oldBalance: oldBalance,
            newBalance: newBalance,
            changeType: CashBalanceChangeType.cashExpense,
            reason: 'تعديل مصروف نقدي: ${expense.note ?? 'بدون ملاحظة'}',
            details:
                'فرق المبلغ: $difference (من ${oldExpense.amount} إلى ${expense.amount})',
          );

          debugPrint(
            '[FINANCE] Cash expense updated: difference $difference, New balance: $newBalance',
          );
        } else {
          // Changed from non-cash to cash: deduct full amount
          final oldBalance = _totalCashBalance;
          final newBalance = oldBalance - expense.amount;

          await _logAndUpdateCashBalance(
            oldBalance: oldBalance,
            newBalance: newBalance,
            changeType: CashBalanceChangeType.cashExpense,
            reason: 'تحويل إلى مصروف نقدي: ${expense.note ?? 'بدون ملاحظة'}',
            details: 'تم تحويل من ${oldExpense.source.name} إلى نقدي',
          );

          debugPrint(
            '[FINANCE] Expense changed to cash: ${expense.amount}, New balance: $newBalance',
          );
        }
      } else if (oldExpense?.source == TransactionSource.cash &&
          expense.source != TransactionSource.cash) {
        // Changed from cash to non-cash: add back the old amount
        final oldBalance = _totalCashBalance;
        final newBalance = oldBalance + oldExpense!.amount;

        await _logAndUpdateCashBalance(
          oldBalance: oldBalance,
          newBalance: newBalance,
          changeType: CashBalanceChangeType.expenseDeletion,
          reason: 'تحويل من مصروف نقدي: ${expense.note ?? 'بدون ملاحظة'}',
          details: 'تم تحويل من نقدي إلى ${expense.source.name}',
        );

        debugPrint(
          '[FINANCE] Expense changed from cash: ${oldExpense.amount}, New balance: $newBalance',
        );
      }
    }

    // After saving, refresh the data for the currently selected date
    // to ensure the UI is up-to-date.
    await fetchFinancialDataForSelectedDate();
  }

  Future<void> deleteExpense(int expenseId) async {
    // Get the expense before deleting to check if it's a cash expense
    final expense = await dbHelper.getExpenseById(expenseId);

    await dbHelper.deleteExpense(expenseId);

    // If it was a cash expense, add the amount back to total cash balance
    if (expense != null && expense.source == TransactionSource.cash) {
      final oldBalance = _totalCashBalance;
      final newBalance = oldBalance + expense.amount;

      await _logAndUpdateCashBalance(
        oldBalance: oldBalance,
        newBalance: newBalance,
        changeType: CashBalanceChangeType.expenseDeletion,
        reason: 'حذف مصروف نقدي: ${expense.note ?? 'بدون ملاحظة'}',
        details: 'مبلغ محذوف: ${expense.amount}',
      );

      debugPrint(
        '[FINANCE] Cash expense deleted: ${expense.amount}, New balance: $newBalance',
      );
    }

    // Refresh data
    await fetchFinancialDataForSelectedDate();
  }

  /// Handle debt transactions with cash balance impact
  Future<DebtEntry> addDebtTransaction(DebtEntry debtEntry) async {
    // Save the debt entry to database
    final savedEntry = await dbHelper.createDebtEntry(debtEntry);

    // Handle cash balance update if payment method is cash
    if (debtEntry.paymentMethod == PaymentMethod.cash) {
      await _handleCashDebtTransaction(debtEntry);
    }

    // Refresh data
    await fetchFinancialDataForSelectedDate();

    return savedEntry;
  }

  /// Update existing debt transaction
  Future<void> updateDebtTransaction(DebtEntry debtEntry) async {
    // Get old entry to compare
    final oldEntries = await dbHelper.getDebtEntriesForParty(debtEntry.partyId);
    final oldEntry = oldEntries.firstWhere((e) => e.id == debtEntry.id);

    // Update the debt entry in database
    await dbHelper.updateDebtEntry(debtEntry);

    // Handle cash balance changes if payment method changed or amount changed
    if (oldEntry.paymentMethod == PaymentMethod.cash ||
        debtEntry.paymentMethod == PaymentMethod.cash) {
      // Revert old cash transaction
      if (oldEntry.paymentMethod == PaymentMethod.cash) {
        await _revertCashDebtTransaction(oldEntry);
      }
      // Apply new cash transaction
      if (debtEntry.paymentMethod == PaymentMethod.cash) {
        await _handleCashDebtTransaction(debtEntry);
      }
    }

    // Refresh data
    await fetchFinancialDataForSelectedDate();
  }

  /// Revert cash balance changes from a debt transaction
  Future<void> _revertCashDebtTransaction(DebtEntry debtEntry) async {
    final oldBalance = _totalCashBalance;
    late final double newBalance;

    // Reverse the previous transaction
    final wasPayment =
        debtEntry.kind == 'payment' ||
        debtEntry.kind == 'purchase_credit' ||
        debtEntry.kind == 'loan_out';

    if (wasPayment) {
      // Was a payment, so add it back
      newBalance = oldBalance + debtEntry.amount;
    } else {
      // Was a collection, so subtract it
      newBalance = oldBalance - debtEntry.amount;
    }

    await updateTotalCashBalance(newBalance);
  }

  /// Handle cash balance changes for debt transactions
  Future<void> _handleCashDebtTransaction(DebtEntry debtEntry) async {
    final oldBalance = _totalCashBalance;
    late final double newBalance;
    late final CashBalanceChangeType changeType;
    late final String reason;
    late final String details;

    // Determine if this is a payment (decreases cash) or collection (increases cash)
    // payment: تسديد دين للمورد (أدفع مال)
    // purchase_credit: شراء بالدين لكن أدفع نقداً (أدفع مال)
    // loan_out: إقراض شخص (أعطيه مال من رصيدي - أدفع مال)
    // settlement: استلام من مدين (أستلم مال)
    final isPayment =
        debtEntry.kind == 'payment' ||
        debtEntry.kind == 'purchase_credit' ||
        debtEntry.kind == 'loan_out';

    if (isPayment) {
      // Payment: decrease cash balance
      newBalance = oldBalance - debtEntry.amount;
      changeType = CashBalanceChangeType.debtPayment;
      reason = _getPaymentReason(debtEntry);
      details =
          'دفع لطرف: ${await _getPartyName(debtEntry.partyId)} - مبلغ: ${debtEntry.amount}';
    } else {
      // Collection: increase cash balance
      newBalance = oldBalance + debtEntry.amount;
      changeType = CashBalanceChangeType.debtCollection;
      reason = _getCollectionReason(debtEntry);
      details =
          'استلام من طرف: ${await _getPartyName(debtEntry.partyId)} - مبلغ: ${debtEntry.amount}';
    }

    await _logAndUpdateCashBalance(
      oldBalance: oldBalance,
      newBalance: newBalance,
      changeType: changeType,
      reason: reason,
      details: details,
    );

    debugPrint(
      '[FINANCE] Debt transaction processed: ${debtEntry.kind}, Amount: ${debtEntry.amount}, New balance: $newBalance',
    );
  }

  /// Get payment reason based on debt entry kind
  String _getPaymentReason(DebtEntry debtEntry) {
    switch (debtEntry.kind) {
      case 'payment':
        return 'تسديد دفعة دين';
      case 'purchase_credit':
        return 'شراء بالدين (دفع نقداً)';
      case 'loan_out':
        return 'إقراض مبلغ نقداً';
      default:
        return 'دفع دين';
    }
  }

  /// Get collection reason based on debt entry kind
  String _getCollectionReason(DebtEntry debtEntry) {
    switch (debtEntry.kind) {
      case 'settlement':
        return 'استلام دفعة من مدين';
      default:
        return 'استلام من مدين';
    }
  }

  /// Get party name by ID
  Future<String> _getPartyName(int partyId) async {
    try {
      final party = await dbHelper.getPartyById(partyId);
      return party?.name ?? 'غير معروف';
    } catch (e) {
      return 'غير معروف';
    }
  }

  /// إعادة تعيين جميع بيانات اليوم المحدد
  Future<void> resetDayData(DateTime selectedDate) async {
    try {
      debugPrint(
        '[RESET_DAY] بدء إعادة تعيين بيانات يوم ${selectedDate.toString()}',
      );

      // تحديد نطاق اليوم
      final startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final endOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
      );

      // إخفاء جميع المصاريف لهذا اليوم (بدلاً من حذفها)
      final expenses = await dbHelper.getExpensesForDateRange(
        startOfDay,
        endOfDay,
      );
      final db = await dbHelper.database;

      for (final expense in expenses) {
        if (expense.id != null && !expense.isHidden) {
          await db.update(
            'expenses',
            {'is_hidden': 1},
            where: 'id = ?',
            whereArgs: [expense.id],
          );
        }
      }
      debugPrint('[إغلاق_اليوم] تم إخفاء ${expenses.length} مصروف');

      // إخفاء جميع المداخيل لهذا اليوم (بدلاً من حذفها)
      final incomes = await dbHelper.getIncomeForDateRange(
        startOfDay,
        endOfDay,
      );
      for (final income in incomes) {
        if (income.id != null && !income.isHidden) {
          await db.update(
            'income',
            {'is_hidden': 1},
            where: 'id = ?',
            whereArgs: [income.id],
          );
        }
      }
      debugPrint('[إغلاق_اليوم] تم إخفاء ${incomes.length} دخل');

      // حذف لقطات الدرج لهذا اليوم
      final snapshots = await dbHelper.getAllDrawerSnapshots();
      for (final snapshot in snapshots) {
        // فحص إذا كانت اللقطة في نفس اليوم
        if (isSameDay(snapshot.date, selectedDate) && snapshot.id != null) {
          await dbHelper.deleteDrawerSnapshot(snapshot.id!);
        }
      }
      debugPrint('[RESET_DAY] تم حذف لقطات الدرج لليوم المحدد');

      // إعادة تعيين أرصدة الدرج إذا كان هذا هو اليوم المحدد حالياً
      if (isSameDay(selectedDate, dateProvider.selectedDate)) {
        _startOfDayBalance = null;
        _endOfDayBalance = null;
        _drawerStatus = DrawerStatus.pendingEnd;

        // إعادة تعيين القيم المالية لليوم فقط (بدون الرصيد النقدي الإجمالي)
        // ❌ لا نعيد تعيين _totalCashBalance لأنه الرصيد الإجمالي العام
        _grossProfit = 0.0;
        _totalExpenses = 0.0;
        _totalIncome = 0.0;
        _netProfit = 0.0;

        notifyListeners();
      }

      debugPrint('[RESET_DAY] تم إكمال إعادة تعيين بيانات اليوم بنجاح');
    } catch (e) {
      debugPrint('[RESET_DAY] خطأ في إعادة تعيين البيانات: $e');
      rethrow;
    }
  }

  /// التحقق من تطابق التواريخ (نفس اليوم)
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
