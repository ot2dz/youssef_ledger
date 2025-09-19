// lib/presentation/widgets/drawer_history_log.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:youssef_fabric_ledger/core/enums.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/drawer_snapshot.dart';
import 'package:youssef_fabric_ledger/logic/providers/finance_provider.dart';
import 'package:youssef_fabric_ledger/core/formatters/date_formatters.dart';

class DrawerHistoryLog extends StatefulWidget {
  const DrawerHistoryLog({super.key});

  @override
  DrawerHistoryLogState createState() => DrawerHistoryLogState();
}

class DrawerHistoryLogState extends State<DrawerHistoryLog> {
  List<DrawerSnapshot> _snapshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    setState(() {
      _isLoading = true;
    });
    final snapshots = await DatabaseHelper.instance.getAllDrawerSnapshots();
    setState(() {
      _snapshots = snapshots;
      _isLoading = false;
    });
  }

  // --- ✅ التعديل هنا: الدالة الآن تستقبل ID ---
  Future<void> _deleteSnapshot(int id, SnapshotType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف رصيد ${type == SnapshotType.start ? 'البداية' : 'النهاية'} لهذا اليوم؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // --- ✅ وهنا: نستدعي الدالة الصحيحة ---
      await DatabaseHelper.instance.deleteDrawerSnapshot(id);
      Provider.of<FinanceProvider>(context, listen: false).refreshTodayData();
      _loadSnapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_snapshots.isEmpty) {
      return const Center(child: Text('لم يتم تسجيل أي لقطات للدرج بعد.'));
    }

    final groupedSnapshots = groupBy(
      _snapshots,
      (DrawerSnapshot s) => DateFormat('yyyy-MM-dd').format(s.date),
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: groupedSnapshots.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedSnapshots.keys.elementAt(index);
        final snapshotsForDay = groupedSnapshots[dateKey]!;
        final date = DateTime.parse(dateKey);
        return _buildDaySection(context, date, snapshotsForDay);
      },
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<DrawerSnapshot> snapshots,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'د.ج');
    final startSnapshot = snapshots.firstWhereOrNull(
      (s) => s.type == SnapshotType.start,
    );
    final endSnapshot = snapshots.firstWhereOrNull(
      (s) => s.type == SnapshotType.end,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              DateFormatters.formatFullDateArabic(date),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          if (startSnapshot != null)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
              title: const Text('رصيد بداية اليوم'),
              subtitle: Text(currencyFormat.format(startSnapshot.cashAmount)),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                // --- ✅ التعديل هنا: نمرر ID بدلاً من التاريخ ---
                onPressed: () =>
                    _deleteSnapshot(startSnapshot.id!, SnapshotType.start),
              ),
            ),
          if (endSnapshot != null)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.stop, color: Colors.white),
              ),
              title: const Text('رصيد نهاية اليوم'),
              subtitle: Text(currencyFormat.format(endSnapshot.cashAmount)),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                // --- ✅ وهنا أيضًا ---
                onPressed: () =>
                    _deleteSnapshot(endSnapshot.id!, SnapshotType.end),
              ),
            ),
        ],
      ),
    );
  }
}
