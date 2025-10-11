import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/reports_provider.dart';
import 'widgets/filter_bar.dart';
import 'widgets/summary_cards.dart';

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

                  // زر إنشاء تقرير PDF
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _generatePdfReport(context, provider),
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'إنشاء تقرير PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// إنشاء تقرير PDF
  Future<void> _generatePdfReport(
    BuildContext context,
    ReportsProvider provider,
  ) async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await provider.generatePdfReport();

      // إخفاء مؤشر التحميل
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // إظهار رسالة نجاح
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء تقرير PDF بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // إخفاء مؤشر التحميل
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // إظهار رسالة خطأ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
