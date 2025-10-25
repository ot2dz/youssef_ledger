// lib/presentation/widgets/party_balance_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';
import 'package:youssef_fabric_ledger/services/data_cache_service.dart';
import 'package:youssef_fabric_ledger/presentation/screens/party_details_screen.dart';

/// Optimized party balance card with caching
///
/// Uses DataCacheService instead of FutureBuilder for each card,
/// dramatically improving scroll performance when displaying many parties.
class PartyBalanceCard extends StatefulWidget {
  final Party party;
  const PartyBalanceCard({required this.party, super.key});

  @override
  State<PartyBalanceCard> createState() => _PartyBalanceCardState();
}

class _PartyBalanceCardState extends State<PartyBalanceCard> {
  double? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    if (!mounted) return;

    final balance = await DataCacheService.instance.getPartyBalance(
      widget.party.id!,
    );

    if (!mounted) return;
    setState(() {
      _balance = balance;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // تهيئة صيغة العملة مع استخدام الأرقام اللاتينية
    final currencyFormat = NumberFormat.currency(locale: 'en', symbol: 'د.ج');

    // أثناء انتظار البيانات
    if (_isLoading) {
      return const ListTile(
        title: Text("... جاري حساب الرصيد"),
        subtitle: LinearProgressIndicator(),
      );
    }

    // إذا كان الرصيد صفراً، لا نعرض البطاقة لتنظيف الواجهة
    if (_balance == null || _balance == 0) {
      return const SizedBox.shrink();
    }

    // تحديد النصوص والألوان بناءً على نوع الطرف (مورد أم شخص)
    final bool isVendor = widget.party.type == 'vendor';
    final String label = isVendor ? "مستحق له:" : "مستحق منه:";
    final Color balanceColor = isVendor
        ? Colors.red.shade700
        : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          foregroundColor: Theme.of(context).primaryColor,
          child: Text(widget.party.name.substring(0, 1)),
        ),
        title: Text(
          widget.party.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(label),
        trailing: Text(
          currencyFormat.format(
            _balance!.abs(),
          ), // .abs() لعرض القيمة المطلقة دائماً
          style: TextStyle(
            color: balanceColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        // الجزء الأهم: عند الضغط على البطاقة
        onTap: () {
          // تنفيذ أمر الانتقال إلى شاشة التفاصيل
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PartyDetailsScreen(
                party: widget.party, // نمرر بيانات الطرف
                initialBalance: _balance!, // نمرر الرصيد المحسوب
              ),
            ),
          );
        },
      ),
    );
  }
}
