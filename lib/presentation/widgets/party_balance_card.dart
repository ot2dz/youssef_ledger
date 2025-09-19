// lib/presentation/widgets/party_balance_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';
// تأكد من أن هذا الاستيراد صحيح ويشير إلى مكان ملف شاشة التفاصيل
import 'package:youssef_fabric_ledger/presentation/screens/party_details_screen.dart';

class PartyBalanceCard extends StatelessWidget {
  final Party party;
  const PartyBalanceCard({required this.party, super.key});

  @override
  Widget build(BuildContext context) {
    // تهيئة صيغة العملة مع استخدام الأرقام اللاتينية
    final currencyFormat = NumberFormat.currency(locale: 'en', symbol: 'د.ج');

    // نستخدم FutureBuilder لجلب الرصيد بشكل غير متزامن لكل بطاقة على حدة
    return FutureBuilder<double>(
      future: DatabaseHelper.instance.getPartyBalance(party.id!),
      builder: (context, snapshot) {
        // أثناء انتظار البيانات، يمكن عرض عنصر نائب بسيط
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text("... جاري حساب الرصيد"),
            subtitle: LinearProgressIndicator(),
          );
        }

        // في حال حدوث خطأ أثناء جلب البيانات
        if (snapshot.hasError) {
          return ListTile(
            title: Text(party.name),
            subtitle: const Text(
              "خطأ في حساب الرصيد",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // إذا لم يكن هناك بيانات (وهو أمر غير مرجح إلا في حالة الخطأ)
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final balance = snapshot.data!;
        // إذا كان الرصيد صفراً، لا نعرض البطاقة لتنظيف الواجهة
        if (balance == 0) {
          return const SizedBox.shrink();
        }

        // تحديد النصوص والألوان بناءً على نوع الطرف (مورد أم شخص)
        final bool isVendor = party.type == 'vendor';
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
              child: Text(party.name.substring(0, 1)),
            ),
            title: Text(
              party.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(label),
            trailing: Text(
              currencyFormat.format(
                balance.abs(),
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
                    party: party, // نمرر بيانات الطرف
                    initialBalance: balance, // نمرر الرصيد المحسوب
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
