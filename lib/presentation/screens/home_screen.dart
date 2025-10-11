import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:youssef_fabric_ledger/logic/providers/date_provider.dart';
import 'package:youssef_fabric_ledger/logic/providers/finance_provider.dart';
import 'package:youssef_fabric_ledger/presentation/screens/settings_screen.dart';
import 'package:youssef_fabric_ledger/presentation/screens/cash_balance_log_screen.dart';
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
                  'دفتر التاجر',
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
                  preferredSize: const Size.fromHeight(
                    72.0,
                  ), // زيادة الارتفاع لتجنب الفيض
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0, // تقليل padding قليلاً لتوفير مساحة
                    ),
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
                              size: 24,
                            ),
                            onPressed: () => dateProvider.previousDay(),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
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
                                fontSize: 14,
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
                              size: 24,
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
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.grey),
                  onPressed: () => _navigateToCashBalanceLog(context),
                  tooltip: 'سجل التغييرات',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _showEditBalanceDialog(context),
                  tooltip: 'تعديل الرصيد',
                ),
              ],
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
                    Expanded(
                      child: _buildStatusColumn(
                        'الرصيد الافتتاحي',
                        currencyFormat.format(status['openingBalance'] ?? 0.0),
                        Icons.login,
                        Colors.blueGrey,
                      ),
                    ),
                    Expanded(
                      child: _buildStatusColumn(
                        'الرصيد الختامي',
                        currencyFormat.format(status['closingBalance'] ?? 0.0),
                        Icons.logout,
                        Colors.blueGrey,
                      ),
                    ),
                    Expanded(
                      child: _buildStatusColumn(
                        'الفرق',
                        currencyFormat.format(status['difference'] ?? 0.0),
                        (status['difference'] ?? 0.0) >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        (status['difference'] ?? 0.0) >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                // زر إغلاق اليوم
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCloseDayDialog(context),
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text(
                      'إغلاق اليوم وإعادة التعيين',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  void _showCloseDayDialog(BuildContext context) {
    final TextEditingController dateController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    dateController.text = DateFormatters.formatShortDate(selectedDate);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إغلاق اليوم وإعادة التعيين',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ تحذير:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سيتم إعادة تعيين جميع بيانات اليوم المحدد:\n• رصيد بداية ونهاية اليوم\n• جميع المصاريف والمداخيل',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر التاريخ:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    locale: const Locale('ar'),
                  );
                  if (picked != null && picked != selectedDate) {
                    selectedDate = picked;
                    dateController.text = DateFormatters.formatShortDate(
                      selectedDate,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: const Color(0xFF6366F1),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetDayData(context, selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إغلاق وإعادة تعيين',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetDayData(BuildContext context, DateTime selectedDate) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final financeProvider = Provider.of<FinanceProvider>(
        context,
        listen: false,
      );

      // إعادة تعيين بيانات اليوم
      await financeProvider.resetDayData(selectedDate);

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إغلاق يوم ${DateFormatters.formatShortDate(selectedDate)} وإعادة تعيين بياناته بنجاح',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // إعادة تحميل البيانات
      financeProvider.fetchFinancialDataForSelectedDate();
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إعادة تعيين البيانات: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _navigateToCashBalanceLog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CashBalanceLogScreen()),
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
                  financeProvider.updateTotalCashBalanceWithLog(
                    newBalance: newBalance,
                    reason: 'تعديل يدوي للرصيد النقدي',
                    details: 'تم التعديل من الشاشة الرئيسية',
                  );
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
