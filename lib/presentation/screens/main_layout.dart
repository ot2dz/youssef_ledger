// lib/presentation/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youssef_fabric_ledger/presentation/screens/expenses_screen.dart';
import 'package:youssef_fabric_ledger/presentation/screens/home_screen.dart';
import 'package:youssef_fabric_ledger/presentation/screens/debts_screen.dart';
import 'package:youssef_fabric_ledger/presentation/screens/settings_screen.dart';
import 'package:youssef_fabric_ledger/presentation/widgets/add_transaction_modal.dart';
import 'package:youssef_fabric_ledger/logic/providers/finance_provider.dart';
import 'package:youssef_fabric_ledger/features/reports/presentation/reports_screen.dart';
import 'package:youssef_fabric_ledger/features/reports/logic/reports_provider.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainLayout({super.key, this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Key _expensesKey = UniqueKey(); // مفتاح فريد لشاشة المصروفات

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  /// عرض مربع حوار تأكيد تسجيل الخروج
  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('تسجيل الخروج'),
            ],
          ),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );

    if (result == true && widget.onLogout != null) {
      widget.onLogout!();
    }
  }

  /// الدالة التي تفتح النافذة المنبثقة من الأسفل لإضافة مصروف جديد
  void _showAddTransactionModal() async {
    // 1. انتظر النتيجة من النافذة المنبثقة
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddTransactionModal(),
    );

    // 2. إذا كانت النتيجة 'true' (يعني تم الحفظ بنجاح)، قم بتحديث البيانات
    if (result == true && mounted) {
      // استدعاء دالة التحديث في الـ Provider
      context.read<FinanceProvider>().refreshTodayData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'دفتر التاجر',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'logout') {
                  await _showLogoutConfirmation();
                } else if (value == 'settings') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded),
                      SizedBox(width: 8),
                      Text('الإعدادات'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('تسجيل الخروج'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: <Widget>[
            const HomeScreen(),
            ExpensesScreen(
              key: _expensesKey,
            ), // Expenses Screen with unique key
            const DebtsScreen(), // Debts Screen
            ChangeNotifierProvider(
              create: (_) => ReportsProvider(),
              child: const ReportsScreen(),
            ), // Reports Screen
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _showAddTransactionModal,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          elevation: 16,
          color: Colors.white,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(Icons.home_rounded, 'الرئيسية', 0),
                _buildNavItem(
                  Icons.account_balance_wallet_rounded,
                  'الماليات',
                  1,
                ),
                const SizedBox(width: 48), // Spacer for the FAB
                _buildNavItem(Icons.people_alt_rounded, 'الديون', 2),
                _buildNavItem(Icons.bar_chart_rounded, 'التقارير', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF9CA3AF),
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
