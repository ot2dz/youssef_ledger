import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/reports_provider.dart';
import '../data/models.dart';
import 'widgets/filter_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadReportData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildModernHeader(),

            // Content
            Expanded(
              child: Consumer<ReportsProvider>(
                builder: (context, provider, child) {
                  if (provider.reportData.isLoading) {
                    return _buildLoadingState();
                  }

                  if (provider.reportData.error != null) {
                    return _buildErrorState(provider);
                  }

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact Filters
                          _buildCompactFilters(),
                          const SizedBox(height: 20),

                          // Smart Insights
                          _buildSmartInsights(provider),
                          const SizedBox(height: 16),

                          // Modern Financial Summary
                          const ModernSummaryCards(),
                          const SizedBox(height: 24),

                          // PDF Export Button
                          _buildPdfExportButton(provider),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 التقارير المالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تحليل شامل لأداءك المالي',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _showFilters ? Icons.close : Icons.tune,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: 'الفلاتر',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? null : 0,
      child: _showFilters
          ? Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: const FilterBar(),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSmartInsights(ReportsProvider provider) {
    final data = provider.reportData;
    final netProfit = data.netProfitTotal;
    final isPositive = netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? 'أداء ممتاز! 🎉' : 'انتبه للمصروفات ⚠️',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPositive
                      ? 'أرباحك في تحسن مستمر'
                      : 'راجع مصروفاتك هذه الفترة',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfExportButton(ReportsProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _generatePdfReport(context, provider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'تصدير تقرير PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحليل البيانات...',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReportsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.reportData.error!,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadReportData(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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

// Modern Summary Cards Component
class ModernSummaryCards extends StatelessWidget {
  const ModernSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        final data = provider.reportData;
        final reportType = provider.filterState.reportType;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'الملخص المالي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (reportType == ReportType.all) ...[
                // All data view
                Row(
                  children: [
                    Expanded(
                      child: _ModernMetricCard(
                        title: 'إجمالي الدخل',
                        amount: data.incomeTotal,
                        icon: Icons.trending_up,
                        color: const Color(0xFF10B981),
                        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModernMetricCard(
                        title: 'إجمالي المصروفات',
                        amount: data.expensesTotal,
                        icon: Icons.trending_down,
                        color: const Color(0xFFEF4444),
                        gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ModernMetricCard(
                  title: 'صافي الربح',
                  amount: data.netProfitTotal,
                  icon: data.netProfitTotal >= 0
                      ? Icons.account_balance_wallet
                      : Icons.warning,
                  color: data.netProfitTotal >= 0
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFF59E0B),
                  gradient: data.netProfitTotal >= 0
                      ? const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]
                      : const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  isWide: true,
                ),
              ] else if (reportType == ReportType.income) ...[
                _ModernMetricCard(
                  title: 'إجمالي الدخل',
                  amount: data.incomeTotal,
                  icon: Icons.trending_up,
                  color: const Color(0xFF10B981),
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                  isWide: true,
                ),
              ] else if (reportType == ReportType.expenses) ...[
                _ModernMetricCard(
                  title: 'إجمالي المصروفات',
                  amount: data.expensesTotal,
                  icon: Icons.trending_down,
                  color: const Color(0xFFEF4444),
                  gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                  isWide: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ModernMetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final bool isWide;

  const _ModernMetricCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.gradient,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0 د.ج';

    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formattedAmount;
    if (absAmount >= 1000000) {
      formattedAmount = '${(absAmount / 1000000).toStringAsFixed(1)}م';
    } else if (absAmount >= 1000) {
      formattedAmount = '${(absAmount / 1000).toStringAsFixed(1)}ك';
    } else {
      formattedAmount = absAmount.toStringAsFixed(0);
    }

    final sign = isNegative ? '-' : '';
    return '$sign$formattedAmount د.ج';
  }
}
