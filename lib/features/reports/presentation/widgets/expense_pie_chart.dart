import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../logic/reports_provider.dart';
import '../../data/models.dart';

class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'توزيع المصروفات حسب الفئة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Consumer<ReportsProvider>(
              builder: (context, provider, _) {
                final data = provider.reportData.expensesByCategory;

                if (data.isEmpty) {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد مصروفات للعرض',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final total = data.fold<double>(
                  0,
                  (sum, item) => sum + item.amount,
                );

                return Column(
                  children: [
                    // Pie Chart
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _createPieSections(data, total, theme),
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Legend
                    _buildLegend(data, total, theme),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieSections(
    List<ExpenseCategoryData> data,
    double total,
    ThemeData theme,
  ) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = category.getPercentage(total);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        value: category.amount,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        showTitle: percentage > 5, // Only show title if > 5%
      );
    }).toList();
  }

  Widget _buildLegend(
    List<ExpenseCategoryData> data,
    double total,
    ThemeData theme,
  ) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];

    return Column(
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final color = colors[index % colors.length];
        final percentage = category.getPercentage(total);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.categoryName,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatAmount(category.amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0 د.ج';

    final absAmount = amount.abs();

    // Format with thousands separators
    final formatter = NumberFormat('#,##0.00', 'ar');
    final formattedAmount = formatter.format(absAmount);

    return '$formattedAmount د.ج';
  }
}
