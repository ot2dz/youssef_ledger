import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:youssef_fabric_ledger/logic/providers/date_provider.dart';
import 'package:youssef_fabric_ledger/logic/providers/finance_provider.dart';
import 'package:youssef_fabric_ledger/presentation/screens/settings_screen.dart';
import 'package:youssef_fabric_ledger/core/formatters/date_formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Data is now fetched automatically by the provider when the date changes.
    // We can trigger an initial fetch here if needed, but it's handled by the provider's constructor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().fetchFinancialDataForSelectedDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ar',
      symbol: 'د.ج ',
      decimalDigits: 2,
    );
    final dateProvider = context.watch<DateProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<FinanceProvider>(
        builder: (context, financeProvider, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
                  'دفتر أقمشة يوسف',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                centerTitle: true,
                pinned: true,
                floating: true,
                elevation: 0,
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      tooltip: 'الإعدادات',
                      color: Colors.white,
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => dateProvider.previousDay(),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              DateFormatters.formatFullDateArabic(
                                dateProvider.selectedDate,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => dateProvider.nextDay(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // إجمالي الرصيد النقدي
                    _buildEditableBalanceCard(
                      context,
                      'إجمالي الرصيد النقدي',
                      currencyFormat.format(financeProvider.totalCashBalance),
                      Icons.account_balance,
                      Colors.purple,
                    ),

                    // نص توضيحي حول تحديث الرصيد النقدي
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'يتم تحديث الرصيد تلقائياً عند إضافة مصروف نقدي أو إغلاق اليوم',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // صف 1: مصروفات اليوم + دخل اليوم
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallSummaryCard(
                            'مصروفات اليوم',
                            currencyFormat.format(
                              financeProvider.totalExpenses,
                            ),
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSmallSummaryCard(
                            'دخل اليوم',
                            currencyFormat.format(financeProvider.totalIncome),
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    // صف 2: ربح اليوم (20%)
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallSummaryCard(
                            'ربح اليوم (20%)',
                            currencyFormat.format(financeProvider.dailyProfit),
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    // بطاقة: صافي ربح اليوم = ربح اليوم - مصروفات اليوم
                    _buildSummaryCard(
                      'صافي ربح اليوم',
                      currencyFormat.format(financeProvider.netProfit),
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),

                    // حالة الدرج
                    _buildDrawerStatusCard(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableBalanceCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () => _showEditBalanceDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerStatusCard() {
    return Consumer<FinanceProvider>(
      builder: (context, financeProvider, child) {
        final status = financeProvider.drawerFinalState;
        final currencyFormat = NumberFormat.currency(
          locale: 'ar',
          symbol: 'د.ج ',
          decimalDigits: 2,
        );

        return Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حالة الدرج النهائية',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (financeProvider.isCrossDateCalculation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync_alt,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'متقاطع',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (financeProvider.isCrossDateCalculation)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'من ${_formatDateOnly(financeProvider.effectiveStartDate!)} إلى ${_formatDateOnly(financeProvider.effectiveEndDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusColumn(
                      'الرصيد الافتتاحي',
                      currencyFormat.format(status['openingBalance'] ?? 0.0),
                      Icons.login,
                      Colors.blueGrey,
                    ),
                    _buildStatusColumn(
                      'الرصيد الختامي',
                      currencyFormat.format(status['closingBalance'] ?? 0.0),
                      Icons.logout,
                      Colors.blueGrey,
                    ),
                    _buildStatusColumn(
                      'الفرق',
                      currencyFormat.format(status['difference'] ?? 0.0),
                      (status['difference'] ?? 0.0) >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      (status['difference'] ?? 0.0) >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusColumn(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditBalanceDialog(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(
      context,
      listen: false,
    );
    final TextEditingController controller = TextEditingController(
      text: financeProvider.totalCashBalance.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل إجمالي الرصيد النقدي'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'الرصيد الجديد',
              prefixText: 'د.ج ',
            ),
            textDirection: ui.TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                final double? newBalance = double.tryParse(controller.text);
                if (newBalance != null) {
                  financeProvider.updateTotalCashBalance(newBalance);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateOnly(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }
}
