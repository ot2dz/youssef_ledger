import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:youssef_fabric_ledger/models/cash_balance_log.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';

/// Screen for viewing cash balance change log with chronological listing
class CashBalanceLogScreen extends StatefulWidget {
  const CashBalanceLogScreen({super.key});

  @override
  State<CashBalanceLogScreen> createState() => _CashBalanceLogScreenState();
}

class _CashBalanceLogScreenState extends State<CashBalanceLogScreen> {
  List<CashBalanceLog> _logs = [];
  bool _isLoading = true;
  CashBalanceChangeType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      List<CashBalanceLog> logs;

      if (_selectedType != null) {
        logs = await DatabaseHelper.instance.getCashBalanceLogsByType(
          _selectedType!,
          limit: 100,
        );
      } else if (_startDate != null && _endDate != null) {
        logs = await DatabaseHelper.instance.getCashBalanceLogsByDateRange(
          _startDate!,
          _endDate!,
        );
      } else {
        logs = await DatabaseHelper.instance.getCashBalanceLogs(limit: 100);
      }

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل تغييرات الرصيد النقدي'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatsDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                if (_logs.isNotEmpty) _buildStatsCard(),
                Expanded(child: _buildLogsList()),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تغييرات في الرصيد',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textDirection: ui.TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            'سيظهر هنا سجل جميع التغييرات على الرصيد النقدي',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_selectedType != null || _startDate != null)
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('إزالة الفلاتر'),
            ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    // Group logs by date
    final groupedLogs = <String, List<CashBalanceLog>>{};
    for (final log in _logs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.timestamp);
      groupedLogs.putIfAbsent(dateKey, () => []).add(log);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedLogs.length,
      itemBuilder: (context, index) {
        final dateKey = groupedLogs.keys.elementAt(index);
        final logsForDate = groupedLogs[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date, logsForDate.length),
            const SizedBox(height: 8),
            ...logsForDate.map((log) => _buildLogItem(log)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, int count) {
    final isToday = DateTime.now().difference(date).inDays == 0;
    final isYesterday = DateTime.now().difference(date).inDays == 1;

    String dateText;
    if (isToday) {
      dateText = 'اليوم';
    } else if (isYesterday) {
      dateText = 'أمس';
    } else {
      // Get month name in Arabic
      final monthNames = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      final day = date.day;
      final month = monthNames[date.month - 1];
      final year = date.year;
      dateText = '$day $month $year';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
            textDirection: ui.TextDirection.rtl,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count تغيير',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(CashBalanceLog log) {
    final isIncrease = log.changeAmount > 0;
    final changeIcon = isIncrease ? Icons.arrow_upward : Icons.arrow_downward;
    final changeColor = isIncrease ? Colors.green : Colors.red;

    // Get type-specific icon
    IconData typeIcon;
    Color typeColor;
    switch (log.changeType) {
      case CashBalanceChangeType.manualEdit:
        typeIcon = Icons.edit;
        typeColor = Colors.blue;
        break;
      case CashBalanceChangeType.cashExpense:
        typeIcon = Icons.shopping_cart;
        typeColor = Colors.red;
        break;
      case CashBalanceChangeType.dayClosing:
        typeIcon = Icons.close;
        typeColor = Colors.green;
        break;
      case CashBalanceChangeType.expenseDeletion:
        typeIcon = Icons.restore;
        typeColor = Colors.orange;
        break;
      case CashBalanceChangeType.debtPayment:
        typeIcon = Icons.payment;
        typeColor = Colors.purple;
        break;
      case CashBalanceChangeType.debtCollection:
        typeIcon = Icons.account_balance_wallet;
        typeColor = Colors.teal;
        break;
      case CashBalanceChangeType.cashIncome:
        typeIcon = Icons.attach_money;
        typeColor = Colors.green;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.changeTypeDescription,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: ui.TextDirection.rtl,
                      ),
                      if (log.reason.isNotEmpty && log.reason != 'null')
                        Text(
                          log.reason,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textDirection: ui.TextDirection.rtl,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(changeIcon, color: changeColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${log.changeAmount.abs().toStringAsFixed(2)} د.ج',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: changeColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('HH:mm').format(log.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (log.details != null) ...[
              const SizedBox(height: 8),
              Text(
                log.details!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textDirection: ui.TextDirection.rtl,
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'الرصيد السابق: ${log.oldBalance.toStringAsFixed(2)} د.ج',
                    style: Theme.of(context).textTheme.bodySmall,
                    textDirection: ui.TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'الرصيد الجديد: ${log.newBalance.toStringAsFixed(2)} د.ج',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: ui.TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فلترة السجل', textDirection: ui.TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter by type
            DropdownButtonFormField<CashBalanceChangeType?>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع التغيير',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<CashBalanceChangeType?>(
                  value: null,
                  child: Text(
                    'جميع الأنواع',
                    textDirection: ui.TextDirection.rtl,
                  ),
                ),
                ...CashBalanceChangeType.values.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      _getChangeTypeDisplayName(type),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            // Date range
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    child: Text(
                      _startDate != null
                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                          : 'من تاريخ',
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate:
                            _startDate ??
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    child: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : 'إلى تاريخ',
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('إزالة الفلاتر'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadLogs();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _startDate = null;
      _endDate = null;
    });
    Navigator.of(context).pop();
    _loadLogs();
  }

  Widget _buildStatsCard() {
    final totalIncreased = _logs
        .where((log) => log.changeAmount > 0)
        .fold(0.0, (sum, log) => sum + log.changeAmount);
    final totalDecreased = _logs
        .where((log) => log.changeAmount < 0)
        .fold(0.0, (sum, log) => sum + log.changeAmount.abs());

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'إحصائيات الفترة',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textDirection: ui.TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'إجمالي الزيادات',
                  '${totalIncreased.toStringAsFixed(2)} د.ج',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'إجمالي النقصان',
                  '${totalDecreased.toStringAsFixed(2)} د.ج',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات لعرض الإحصائيات')),
      );
      return;
    }

    // Group by change type
    final Map<CashBalanceChangeType, List<CashBalanceLog>> groupedByType = {};
    for (final log in _logs) {
      groupedByType.putIfAbsent(log.changeType, () => []).add(log);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إحصائيات مفصلة',
          textDirection: ui.TextDirection.rtl,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...groupedByType.entries.map((entry) {
                final type = entry.key;
                final logs = entry.value;
                final totalAmount = logs.fold(
                  0.0,
                  (sum, log) => sum + log.amount,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.value,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textDirection: ui.TextDirection.rtl,
                        ),
                        Text(
                          'العدد: ${logs.length}',
                          textDirection: ui.TextDirection.rtl,
                        ),
                        Text(
                          'المجموع: ${totalAmount.toStringAsFixed(2)} د.ج',
                          textDirection: ui.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _getChangeTypeDisplayName(CashBalanceChangeType type) {
    switch (type) {
      case CashBalanceChangeType.manualEdit:
        return 'تعديل يدوي';
      case CashBalanceChangeType.cashExpense:
        return 'مصروف نقدي';
      case CashBalanceChangeType.dayClosing:
        return 'إقفال يوم';
      case CashBalanceChangeType.expenseDeletion:
        return 'حذف مصروف';
      case CashBalanceChangeType.debtPayment:
        return 'تحصيل دين نقدي';
      case CashBalanceChangeType.debtCollection:
        return 'دفع دين نقدي';
      case CashBalanceChangeType.cashIncome:
        return 'دخل نقدي';
    }
  }
}
