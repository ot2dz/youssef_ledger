// lib/presentation/screens/drawer_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:youssef_fabric_ledger/core/enums.dart';
import 'package:youssef_fabric_ledger/logic/providers/date_provider.dart';
import 'package:youssef_fabric_ledger/logic/providers/finance_provider.dart';
import 'package:youssef_fabric_ledger/core/formatters/date_formatters.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startBalanceController;
  late TextEditingController _endBalanceController;
  late FinanceProvider _financeProvider;
  late DateProvider _dateProvider;

  @override
  void initState() {
    super.initState();
    _financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    _dateProvider = Provider.of<DateProvider>(context, listen: false);
    final startSnapshot = _financeProvider.drawerSnapshots['start'];
    final endSnapshot = _financeProvider.drawerSnapshots['end'];

    // Use effective start balance from FinanceProvider logic
    final effectiveStartBalance =
        startSnapshot?.cashAmount ?? _financeProvider.startOfDayBalance;

    _startBalanceController = TextEditingController(
      text: effectiveStartBalance?.toString() ?? '',
    );
    _endBalanceController = TextEditingController(
      text: endSnapshot?.cashAmount.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _startBalanceController.dispose();
    _endBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveSnapshots() async {
    if (_formKey.currentState!.validate()) {
      final startAmount = double.tryParse(_startBalanceController.text) ?? 0.0;
      final endAmount = double.tryParse(_endBalanceController.text) ?? 0.0;
      final date = _dateProvider.selectedDate;

      // Save start balance
      await _financeProvider.saveDrawerSnapshot(
        date: date,
        type: SnapshotType.start,
        amount: startAmount,
      );

      // Save end balance
      await _financeProvider.saveDrawerSnapshot(
        date: date,
        type: SnapshotType.end,
        amount: endAmount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات الدرج بنجاح')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة درج يوم ${DateFormatters.formatCustomDate(_dateProvider.selectedDate, 'yMMMd')}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 24),
              _buildSummaryCard(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveSnapshots,
                child: const Text('حفظ التغييرات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أرصدة الدرج', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startBalanceController,
              decoration: const InputDecoration(
                labelText: 'رصيد بداية اليوم',
                prefixIcon: Icon(Icons.wb_sunny_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رصيد بداية اليوم';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endBalanceController,
              decoration: const InputDecoration(
                labelText: 'رصيد نهاية اليوم',
                prefixIcon: Icon(Icons.nightlight_round),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رصيد نهاية اليوم';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        final turnover = provider.calculatedTurnover;
        final sales = provider.totalIncome;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص اليوم',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.sync_alt, color: Colors.blue),
                  title: const Text('دورة رأس المال (Turnover)'),
                  trailing: Text(
                    NumberFormat.currency(
                      locale: 'ar_EG',
                      symbol: 'ج.م',
                    ).format(turnover),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.point_of_sale, color: Colors.green),
                  title: const Text('إجمالي الدخل (المبيعات)'),
                  trailing: Text(
                    NumberFormat.currency(
                      locale: 'ar_EG',
                      symbol: 'ج.م',
                    ).format(sales),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
