import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/reports_provider.dart';
import 'widgets/filter_bar.dart';
import 'widgets/summary_cards.dart';
import 'widgets/profit_chart.dart';
import 'widgets/expense_pie_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadReportData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<ReportsProvider>(
          builder: (context, provider, child) {
            if (provider.reportData.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.reportData.error != null) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.reportData.error!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadReportData(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Bar
                  const FilterBar(),
                  const SizedBox(height: 24),

                  // Summary Cards
                  const SummaryCards(),
                  const SizedBox(height: 24),

                  // Charts Section
                  Text(
                    'الرسوم البيانية',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profit Chart
                  const ProfitChart(),
                  const SizedBox(height: 24),

                  // Expense Pie Chart
                  const ExpensePieChart(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
