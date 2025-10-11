// lib/presentation/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:collection/collection.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/expense.dart';
import 'package:youssef_fabric_ledger/data/models/category.dart';
import 'package:youssef_fabric_ledger/presentation/widgets/add_transaction_modal.dart';
import 'package:youssef_fabric_ledger/presentation/widgets/drawer_history_log.dart';
import 'package:youssef_fabric_ledger/core/enums.dart';
import 'package:youssef_fabric_ledger/core/formatters/date_formatters.dart';
import 'package:youssef_fabric_ledger/core/utils/icon_utils.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // متغير لتخزين الحالة الحالية ('expenses' or 'drawer')
  String _selectedView = 'expenses';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'السجلات المالية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // --- أزرار التبديل الجديدة هنا ---
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFF6B7280),
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                ),
                segments: const [
                  ButtonSegment(
                    value: 'expenses',
                    label: Text('المصروفات'),
                    icon: Icon(Icons.payment_rounded),
                  ),
                  ButtonSegment(
                    value: 'drawer',
                    label: Text('الدرج'),
                    icon: Icon(Icons.inbox_rounded),
                  ),
                ],
                selected: {_selectedView},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedView = newSelection.first;
                  });
                },
              ),
            ),

            // --- عرض المحتوى بناءً على الزر المختار ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedView == 'expenses'
                    ? const ExpensesListView() // عرض قائمة المصروفات
                    : const DrawerHistoryLog(), // عنصر نائب لسجل الدرج
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- فصلنا منطق عرض قائمة المصروفات في ويدجت خاص به ---
class ExpensesListView extends StatefulWidget {
  const ExpensesListView({super.key});

  @override
  _ExpensesListViewState createState() => _ExpensesListViewState();
}

class _ExpensesListViewState extends State<ExpensesListView> {
  late Future<List<Expense>> _expensesFuture;
  String _selectedTimeFilter =
      'all'; // 'all', 'today', 'week', 'month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تحميل البيانات عند العودة للشاشة
    _loadExpenses();
  }

  /// تحميل المصروفات حسب الفلتر المحدد
  void _loadExpenses() {
    setState(() {
      _expensesFuture = _getFilteredExpenses();
    });
  }

  // --- ✅ دالة جديدة لإعادة تحميل البيانات ---
  void _refreshExpenses() {
    setState(() {
      _expensesFuture = _getFilteredExpenses();
    });
  }

  /// جلب المصروفات المفلترة حسب الفترة الزمنية
  Future<List<Expense>> _getFilteredExpenses() async {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_selectedTimeFilter) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day + 1);
        break;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = DateTime(now.year, now.month, now.day + 1);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate;
          endDate = DateTime(
            _customEndDate!.year,
            _customEndDate!.month,
            _customEndDate!.day + 1,
          );
        }
        break;
      default:
        return DatabaseHelper.instance.getExpensesForDateRange(
          DateTime(2000),
          DateTime.now().add(const Duration(days: 1)),
        );
    }

    if (startDate != null && endDate != null) {
      return DatabaseHelper.instance.getExpensesForDateRange(
        startDate,
        endDate,
      );
    }
    return DatabaseHelper.instance.getExpensesForDateRange(
      DateTime(2000),
      DateTime.now().add(const Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // فلاتر الوقت - تصميم محدود المساحة
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
          child: _buildTimeFilters(context),
        ),
        // قائمة المصروفات
        Expanded(
          child: FutureBuilder<List<Expense>>(
            future: _expensesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('لم يتم تسجيل أي مصروفات بعد.'),
                );
              }

              final expenses = snapshot.data!;
              // استخدام groupBy لتجميع المصروفات حسب اليوم
              final groupedExpenses = groupBy(
                expenses,
                (Expense e) => DateFormat('yyyy-MM-dd').format(e.date),
              );

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groupedExpenses.keys.length,
                itemBuilder: (context, index) {
                  final dateKey = groupedExpenses.keys.elementAt(index);
                  final expensesForDay = groupedExpenses[dateKey]!;
                  final date = DateTime.parse(dateKey);

                  return _buildDaySection(context, date, expensesForDay);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// بناء فلاتر الوقت
  Widget _buildTimeFilters(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'الفترة الزمنية:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeFilter,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.all_inclusive_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('الكل', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'today',
                    child: Row(
                      children: [
                        Icon(
                          Icons.today_rounded,
                          size: 14,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('اليوم', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'week',
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_week_rounded,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'الأسبوع',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'month',
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('الشهر', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 14,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getCustomDateText(),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    if (newValue == 'custom') {
                      _showCustomDatePicker(context);
                    } else {
                      setState(() {
                        _selectedTimeFilter = newValue;
                      });
                      _loadExpenses();
                    }
                  }
                },
              ),
            ),
          ),
          // أيقونة توضيحية للحذف
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe_left_alt_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'اسحب للحذف',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// الحصول على نص التاريخ المخصص
  String _getCustomDateText() {
    if (_customStartDate != null && _customEndDate != null) {
      final startDate = DateFormatters.formatShortDate(_customStartDate!);
      final endDate = DateFormatters.formatShortDate(_customEndDate!);
      if (startDate == endDate) {
        return startDate; // إذا كان نفس التاريخ
      }
      return '$startDate - $endDate';
    }
    return 'تاريخ مخصص';
  }

  /// عرض منتقي التاريخ المخصص
  Future<void> _showCustomDatePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedTimeFilter = 'custom';
      });
      _loadExpenses();
    }
  }

  // ويدجت لعرض قسم اليوم الواحد
  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<Expense> expenses,
  ) {
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'د.ج');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // رأس اليوم
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatters.formatFullDateArabic(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  currencyFormat.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // قائمة مصروفات اليوم
          ...expenses
              .map(
                (expense) => ExpenseItem(
                  expense: expense,
                  onUpdate: _refreshExpenses, // تمرير الدالة
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}

// ويدجت لعرض عنصر المصروف الواحد
class ExpenseItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onUpdate; // لاستقبال دالة التحديث

  const ExpenseItem({required this.expense, required this.onUpdate, super.key});

  // دالة الحذف مع حوار تأكيد
  Future<void> _delete(BuildContext context) async {
    // إظهار حوار تأكيد الحذف
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنت متأكد من حذف هذا المصروف؟\nالمبلغ: ${expense.amount} د.ج${expense.note != null ? '\nالملاحظة: ${expense.note}' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    // إذا تم تأكيد الحذف
    if (shouldDelete == true) {
      try {
        await DatabaseHelper.instance.deleteExpense(expense.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف المصروف${expense.note != null ? ': ${expense.note}' : ' بنجاح'}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // استدعاء دالة التحديث لإعادة تحميل القائمة
        onUpdate();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف المصروف: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // --- ✅ تفعيل دالة التعديل ---
  void _edit(BuildContext context) async {
    // افتح نافذة الإضافة/التعديل وقم بتمرير المصروف الحالي
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionModal(expenseToEdit: expense),
    );

    // إذا تم الحفظ بنجاح (أُرجعت true)، قم بتحديث القائمة
    if (result == true) {
      onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'د.ج');

    return Slidable(
      key: ValueKey(expense.id),
      // --- الأزرار التي تظهر على اليسار عند السحب ---
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.4, // تحسين عرض الأزرار
        children: [
          SlidableAction(
            onPressed: (ctx) => _delete(context),
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            icon: Icons.delete_forever,
            label: 'حذف',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: _edit,
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'تعديل',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: FutureBuilder<Category?>(
        future: DatabaseHelper.instance.getCategoryById(expense.categoryId),
        builder: (context, snapshot) {
          final categoryName = snapshot.hasData ? snapshot.data!.name : '...';
          final categoryIcon = snapshot.hasData
              ? getIconFromCodePoint(snapshot.data!.iconCodePoint)
              : Icons.label_outline;

          final sourceMap = {
            TransactionSource.cash.name: 'من الكاش',
            TransactionSource.drawer.name: 'من الدرج',
            TransactionSource.bank.name: 'من البنك',
          };

          return ListTile(
            leading: CircleAvatar(child: Icon(categoryIcon, size: 20)),
            title: Text(categoryName),
            subtitle: Text(
              expense.note ??
                  'مصدره: ${sourceMap[expense.source.name] ?? expense.source.name}',
            ),
            trailing: Text(
              currencyFormat.format(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }
}
