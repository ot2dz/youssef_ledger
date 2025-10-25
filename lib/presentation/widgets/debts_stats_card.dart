import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/database_helper.dart';
import '../../data/local/db_bus.dart';

class DebtsStatsCard extends StatefulWidget {
  const DebtsStatsCard({super.key});

  @override
  State<DebtsStatsCard> createState() => _DebtsStatsCardState();
}

class _DebtsStatsCardState extends State<DebtsStatsCard> {
  double _receivableTotal = 0.0;
  double _payableTotal = 0.0;
  bool _isLoading = true;
  late StreamSubscription<void> _dbSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to database changes for auto-refresh
    _dbSubscription = DbBus.instance.stream.listen((_) {
      debugPrint('[UI] DbBus event → DebtsStatsCard refresh');
      _loadStats();
    });

    _loadStats();
  }

  @override
  void dispose() {
    _dbSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Get receivable total (money owed by persons)
      final receivableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM (
          SELECT 
            de.partyId,
            SUM(CASE 
              -- purchase_credit: فقط الآجل يُحتسب كدين
              WHEN de.kind = 'purchase_credit' AND de.paymentMethod = 'credit' THEN de.amount
              -- loan_out: يُحتسب دائمًا (نقدي أو آجل - الإقراض دائمًا دين)
              WHEN de.kind = 'loan_out' THEN de.amount
              -- المعاملات التي تُسدد ديون: بأي طريقة دفع
              WHEN (de.kind = 'payment' OR de.kind = 'settlement') THEN -de.amount
              ELSE 0
            END) as balance
          FROM debt_entries de
          JOIN parties p ON de.partyId = p.id
          WHERE p.type = 'person'
          GROUP BY de.partyId
          HAVING balance > 0
        )
      ''');

      // Get payable total (money owed to vendors)
      final payableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM (
          SELECT 
            de.partyId,
            SUM(CASE 
              -- purchase_credit: فقط الآجل يُحتسب كدين
              WHEN de.kind = 'purchase_credit' AND de.paymentMethod = 'credit' THEN de.amount
              -- loan_out: يُحتسب دائمًا (نقدي أو آجل - الإقراض دائمًا دين)
              WHEN de.kind = 'loan_out' THEN de.amount
              -- المعاملات التي تُسدد ديون: بأي طريقة دفع
              WHEN (de.kind = 'payment' OR de.kind = 'settlement') THEN -de.amount
              ELSE 0
            END) as balance
          FROM debt_entries de
          JOIN parties p ON de.partyId = p.id
          WHERE p.type = 'vendor'
          GROUP BY de.partyId
          HAVING balance > 0
        )
      ''');

      setState(() {
        _receivableTotal = (receivableResult.first['total'] as num).toDouble();
        _payableTotal = (payableResult.first['total'] as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DebtsStatsCard] Error loading stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0 د.ج';
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} د.ج';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Icons.account_balance_wallet_rounded,
            color: theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'ملخص الديون:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CompactStatCard(
                  title: 'لك',
                  value: _formatAmount(_receivableTotal),
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _CompactStatCard(
                  title: 'عليك',
                  value: _formatAmount(_payableTotal),
                  icon: Icons.trending_down_rounded,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
