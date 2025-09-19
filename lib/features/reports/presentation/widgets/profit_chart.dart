import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../logic/reports_provider.dart';
import '../../../../core/formatters/date_formatters.dart';

class ProfitChart extends StatelessWidget {
  const ProfitChart({super.key});

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
              'تطور صافي الربح اليومي',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Consumer<ReportsProvider>(
              builder: (context, provider, _) {
                final data = provider.reportData.dailySeries;

                if (data.isEmpty) {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد بيانات للعرض',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateInterval(data),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatYAxisLabel(value),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _calculateBottomInterval(data.length),
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length)
                                return const SizedBox();

                              final date = data[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormatters.formatShortDate(
                                    date,
                                  ).split('/')[0], // Just day
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.2),
                          ),
                          left: BorderSide(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.2),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.netProfit,
                            );
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.1,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withOpacity(0.1),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final isPositive = spot.y >= 0;
                              return FlDotCirclePainter(
                                radius: 4,
                                color: isPositive
                                    ? theme.colorScheme.primary
                                    : Colors.red,
                                strokeWidth: 2,
                                strokeColor: theme.colorScheme.surface,
                              );
                            },
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              if (index < 0 || index >= data.length)
                                return null;

                              final point = data[index];
                              return LineTooltipItem(
                                '${DateFormatters.formatShortDate(point.date)}\n${_formatAmount(point.netProfit)}',
                                theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onInverseSurface,
                                    ) ??
                                    const TextStyle(),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(List<dynamic> data) {
    if (data.isEmpty) return 1;

    final profits = data.map((d) => d.netProfit as double).toList();
    final maxProfit = profits.reduce((a, b) => a > b ? a : b);
    final minProfit = profits.reduce((a, b) => a < b ? a : b);
    final range = maxProfit - minProfit;

    if (range <= 0) return 1;
    if (range <= 10) return 2;
    if (range <= 100) return 20;
    if (range <= 1000) return 200;
    return (range / 5).roundToDouble();
  }

  double _calculateBottomInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 30) return (dataLength / 7).ceilToDouble();
    return (dataLength / 10).ceilToDouble();
  }

  String _formatYAxisLabel(double value) {
    if (value == 0) return '0';

    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';

    // Keep original short format for Y-axis labels only to save space
    if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toStringAsFixed(0)}ك';
    }
    return '$sign${absValue.toStringAsFixed(0)}';
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
