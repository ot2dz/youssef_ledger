import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/database_helper.dart';

class DebtsStatsCard extends StatefulWidget {
  const DebtsStatsCard({super.key});

  @override
  State<DebtsStatsCard> createState() => _DebtsStatsCardState();
}

class _DebtsStatsCardState extends State<DebtsStatsCard> {
  double _receivableTotal = 0.0;
  double _payableTotal = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
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
              WHEN de.kind = 'purchase_credit' OR de.kind = 'loan_out' THEN de.amount
              WHEN de.kind = 'payment' OR de.kind = 'settlement' THEN -de.amount
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
              WHEN de.kind = 'purchase_credit' OR de.kind = 'loan_out' THEN de.amount
              WHEN de.kind = 'payment' OR de.kind = 'settlement' THEN -de.amount
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الديون',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Financial summary
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'مستحق لك',
                    value: _formatAmount(_receivableTotal),
                    icon: Icons.call_received,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'مستحق عليك',
                    value: _formatAmount(_payableTotal),
                    icon: Icons.call_made,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
