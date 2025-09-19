// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/presentation/screens/manage_categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingsCard(
                context,
                icon: Icons.category_rounded,
                title: 'إدارة الفئات',
                subtitle: 'إضافة وتعديل فئات المصروفات والدخل',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                icon: Icons.backup_rounded,
                title: 'النسخ الاحتياطي',
                subtitle: 'نسخ واستعادة البيانات',
                onTap: () {
                  // TODO: Implement backup functionality
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('قريباً...')));
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                icon: Icons.info_rounded,
                title: 'حول التطبيق',
                subtitle: 'معلومات التطبيق والإصدار',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildAboutDialog(context),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFF6366F1),
            size: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAboutDialog(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Color(0xFF6366F1),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'حول التطبيق',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دفتر أقمشة يوسف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text('الإصدار: 1.0.0', style: TextStyle(color: Color(0xFF6B7280))),
            SizedBox(height: 16),
            Text(
              'تطبيق لإدارة الشؤون المالية لمحل الأقمشة',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'حسناً',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
