import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/reports_provider.dart';
import '../../data/models.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        final data = provider.reportData;
        final reportType = provider.filterState.reportType;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص مالي',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Show different cards based on report type
            if (reportType == ReportType.all ||
                reportType == ReportType.income) ...[
              // Income and expenses cards
              if (reportType == ReportType.all) ...[
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'إجمالي الدخل',
                        amount: data.incomeTotal,
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'إجمالي المصروفات',
                        amount: data.expensesTotal,
                        icon: Icons.trending_down,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Income only
                _SummaryCard(
                  title: 'إجمالي الدخل',
                  amount: data.incomeTotal,
                  icon: Icons.trending_up,
                  color: Colors.green,
                  isWide: true,
                ),
                const SizedBox(height: 12),
              ],
            ],

            if (reportType == ReportType.expenses) ...[
              // Expenses only
              _SummaryCard(
                title: 'إجمالي المصروفات',
                amount: data.expensesTotal,
                icon: Icons.trending_down,
                color: Colors.red,
                isWide: true,
              ),
              const SizedBox(height: 12),
            ],

            // Net profit card (only for all types)
            if (reportType == ReportType.all) ...[
              _SummaryCard(
                title: 'صافي الربح',
                subtitle: 'بعد خصم المصروفات',
                amount: data.netProfitTotal,
                icon: data.netProfitTotal >= 0
                    ? Icons.account_balance_wallet
                    : Icons.warning,
                color: data.netProfitTotal >= 0 ? Colors.blue : Colors.orange,
                isWide: true,
              ),
              const SizedBox(height: 12),

              // Debt summary cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'مستحق لك',
                      amount: data.receivableTotal,
                      icon: Icons.call_received,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'مستحق عليك',
                      amount: data.payableTotal,
                      icon: Icons.call_made,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _SummaryCard({
    required this.title,
    this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _formatAmount(amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0 د.ج';

    final isNegative = amount < 0;
    final absAmount = amount.abs();

    // Format with thousands separators
    final formatter = NumberFormat('#,##0.00', 'ar');
    final formattedAmount = formatter.format(absAmount);

    final sign = isNegative ? '-' : '';
    return '$sign$formattedAmount د.ج';
  }
}
