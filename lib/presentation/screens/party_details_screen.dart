// lib/presentation/screens/party_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart'
    as intl
    hide TextDirection; // <-- تجنّب تضارب TextDirection
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/debt_entry.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';
import '../widgets/debt_action_bar.dart';
import '../widgets/debt_transaction_modal.dart';

class PartyDetailsScreen extends StatefulWidget {
  final Party party;
  final double initialBalance;

  const PartyDetailsScreen({
    required this.party,
    required this.initialBalance,
    super.key,
  });

  @override
  State<PartyDetailsScreen> createState() => _PartyDetailsScreenState();
}

class _PartyDetailsScreenState extends State<PartyDetailsScreen> {
  Future<List<DebtEntry>>? _entriesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// إعادة تحميل البيانات
  void _reload() {
    setState(() {
      _entriesFuture = DatabaseHelper.instance.getDebtEntriesForParty(
        widget.party.id!,
      );
    });
  }

  /// حساب الرصيد من قائمة المعاملات
  double _computeBalance(List<DebtEntry> entries, Party party) {
    double balance = 0.0;
    final bool isVendor = party.type == 'vendor';

    for (final entry in entries) {
      if (isVendor) {
        // للموردين: الشراء والإقراض يزيد ما أدين به (موجب)
        // التسديد والاستلام ينقص (سالب)
        if (entry.kind == 'purchase_credit' || entry.kind == 'loan_out') {
          balance += entry.amount;
        } else if (entry.kind == 'payment' || entry.kind == 'settlement') {
          balance -= entry.amount;
        }
      } else {
        // للأشخاص: الإقراض والشراء يزيد ما يدينون لي (موجب)
        // التسديد والاستلام ينقص (سالب)
        if (entry.kind == 'loan_out' || entry.kind == 'purchase_credit') {
          balance += entry.amount;
        } else if (entry.kind == 'payment' || entry.kind == 'settlement') {
          balance -= entry.amount;
        }
      }
    }

    return balance;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[PartyDetailsScreen] build: id=${widget.party.id}, name=${widget.party.name}, type=${widget.party.type}',
    );
    final currencyFormat = intl.NumberFormat.currency(
      locale: 'en',
      symbol: 'د.ج',
    );
    final bool isVendor = widget.party.type == 'vendor';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.party.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'تعديل',
              onPressed: () async {
                final result = await showDialog<Map<String, String>>(
                  context: context,
                  builder: (context) {
                    final nameController = TextEditingController(
                      text: widget.party.name,
                    );
                    final phoneController = TextEditingController(
                      text: widget.party.phone ?? '',
                    );
                    return AlertDialog(
                      title: const Text('تعديل الطرف'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'الاسم',
                            ),
                          ),
                          TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'الهاتف (اختياري)',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop({
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                            });
                          },
                          child: const Text('حفظ'),
                        ),
                      ],
                    );
                  },
                );
                if (result != null && result['name']!.isNotEmpty) {
                  await DatabaseHelper.instance.updateParty(
                    widget.party.copyWith(
                      name: result['name'],
                      phone: result['phone'],
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث بيانات الطرف')),
                  );
                  setState(() {});
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'حذف',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد الحذف'),
                    content: const Text(
                      'هل أنت متأكد من حذف هذا الطرف؟ سيتم حذف جميع المعاملات المرتبطة به.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('حذف'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseHelper.instance.deleteParty(widget.party.id!);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('تم حذف الطرف')));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // استخدام FutureBuilder واحد للبيانات والرصيد
            Expanded(
              child: FutureBuilder<List<DebtEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    debugPrint(
                      '[PartyDetailsScreen] Loading debt entries for party id=${widget.party.id}...',
                    );
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    debugPrint(
                      '[PartyDetailsScreen] ERROR loading debt entries: \\${snapshot.error}',
                    );
                    return Center(child: Text('حدث خطأ: \\${snapshot.error}'));
                  }
                  final entries = snapshot.data ?? [];
                  final currentBalance = _computeBalance(entries, widget.party);
                  debugPrint(
                    '[PartyDetailsScreen] Loaded ${entries.length} debt entries for party id=${widget.party.id}',
                  );

                  return Column(
                    children: [
                      // بطاقة الرصيد
                      _buildBalanceCard(
                        context,
                        currencyFormat,
                        isVendor,
                        currentBalance,
                      ),
                      // قسم المعاملات
                      if (entries.isEmpty)
                        Expanded(child: _buildEmptyState())
                      else ...[
                        // عنوان قسم المعاملات
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'المعاملات (${entries.length})',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // قائمة المعاملات
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return _buildTransactionCard(
                                entry,
                                currencyFormat,
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: DebtActionBar(
          onFirstActionPressed: () => _handleFirstAction(context, isVendor),
          onSecondActionPressed: () => _handleSecondAction(context, isVendor),
          isVendor: isVendor,
        ),
      ),
    );
  }

  /// بطاقة عرض الرصيد
  Widget _buildBalanceCard(
    BuildContext context,
    intl.NumberFormat currencyFormat,
    bool isVendor,
    double currentBalance,
  ) {
    // تحديد لون المبلغ والنص المساعد
    Color amountColor;
    String helperText;
    IconData? circularIcon;

    if (currentBalance == 0) {
      amountColor = Colors.grey.shade700;
      helperText = 'لا يوجد رصيد';
      circularIcon = null;
    } else if (isVendor) {
      if (currentBalance > 0) {
        // مورد + رصيد موجب = أنت مدين له (أحمر)
        amountColor = Colors.red.shade700;
        helperText = 'مستحق له';
        circularIcon = Icons.keyboard_arrow_up;
      } else {
        // مورد + رصيد سالب = مستحق لك منه (أخضر)
        amountColor = Colors.green.shade700;
        helperText = 'مستحق منه';
        circularIcon = Icons.keyboard_arrow_down;
      }
    } else {
      if (currentBalance > 0) {
        // شخص + رصيد موجب = مستحق لك منه (أخضر)
        amountColor = Colors.green.shade700;
        helperText = 'مستحق منه';
        circularIcon = Icons.keyboard_arrow_down;
      } else {
        // شخص + رصيد سالب = أنت مدين له (أحمر)
        amountColor = Colors.red.shade700;
        helperText = 'مستحق له';
        circularIcon = Icons.keyboard_arrow_up;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تسمية الرصيد
                Text(
                  'الرصيد',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // المبلغ
                Text(
                  currencyFormat.format(currentBalance.abs()),
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // النص المساعد
                Text(
                  helperText,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          // الأيقونة الدائرية
          if (circularIcon != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(circularIcon, color: amountColor, size: 24),
            ),
        ],
      ),
    );
  }

  /// ويدجت لعرض حالة فارغة عند عدم وجود معاملات
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80), // مساحة للأزرار السفلية
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.party.type == 'vendor'
                  ? Icons.store_outlined
                  : Icons.person_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد معاملات مع ${widget.party.name}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ستظهر جميع المعاملات هنا عند إضافتها',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة عرض المعاملة الواحدة
  Widget _buildTransactionCard(
    DebtEntry entry,
    intl.NumberFormat currencyFormat,
  ) {
    // تحديد الأيقونة، اللون، والنص بناءً على نوع المعاملة
    IconData icon;
    Color color;
    String title;
    String relationText;

    final bool isDebtIncrease =
        entry.kind == 'purchase_credit' || entry.kind == 'loan_out';

    if (isDebtIncrease) {
      color = Colors.red;
      if (widget.party.type == 'vendor') {
        title = 'شراء بالدين';
        relationText = 'مستحق لـ ${widget.party.name}';
      } else {
        title = 'إقراض مبلغ';
        relationText = 'مستحق من ${widget.party.name}';
      }
      icon = Icons.arrow_upward;
    } else {
      color = Colors.green;
      if (widget.party.type == 'vendor') {
        title = 'تسديد دفعة';
        relationText = 'دفع لـ ${widget.party.name}';
      } else {
        title = 'استلام دفعة';
        relationText = 'استلام من ${widget.party.name}';
      }
      icon = Icons.arrow_downward;
    }

    // تنسيق التاريخ بشكل طبيعي مع الأرقام اللاتينية
    final dateFormat = intl.DateFormat('dd/MM/yyyy', 'en');
    final formattedDate = dateFormat.format(entry.date);

    return Slidable(
      key: ValueKey(entry.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editDebtEntry(entry),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) => _deleteDebtEntry(entry),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // الصف العلوي: العنوان والأيقونة
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // المبلغ
            Row(
              children: [
                Expanded(
                  child: Text(
                    currencyFormat.format(entry.amount),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // الصف السفلي: التاريخ والرصيد
            Row(
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
                Text(
                  relationText,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            // عرض الملاحظة إذا كانت موجودة
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.note!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// معالج تعديل المعاملة
  void _editDebtEntry(DebtEntry entry) async {
    final result = await showDebtTransactionModal(
      context: context,
      party: widget.party,
      transactionKind: entry.kind,
      existingEntry: entry,
    );

    if (result == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعديل المعاملة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// معالج حذف المعاملة
  void _deleteDebtEntry(DebtEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنت متأكد من حذف هذه المعاملة؟\n\n'
            'المبلغ: ${entry.amount.toStringAsFixed(2)}\n'
            'النوع: ${_getTransactionTypeName(entry.kind)}\n'
            'التاريخ: ${intl.DateFormat('dd/MM/yyyy').format(entry.date)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await DatabaseHelper.instance.deleteDebtEntry(entry.id!);
        _reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المعاملة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// الحصول على اسم نوع المعاملة بالعربية
  String _getTransactionTypeName(String kind) {
    switch (kind) {
      case 'purchase_credit':
        return 'شراء بالدين';
      case 'payment':
        return 'تسديد';
      case 'loan_out':
        return 'إقراض';
      case 'settlement':
        return 'استلام';
      default:
        return kind;
    }
  }

  /// معالج الزر الأول (شراء للموردين أو إقراض للأشخاص)
  void _handleFirstAction(BuildContext context, bool isVendor) async {
    final transactionKind = isVendor ? 'purchase_credit' : 'loan_out';
    final result = await showDebtTransactionModal(
      context: context,
      party: widget.party,
      transactionKind: transactionKind,
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  /// معالج الزر الثاني (تسديد للموردين أو استلام للأشخاص)
  void _handleSecondAction(BuildContext context, bool isVendor) async {
    final transactionKind = isVendor ? 'payment' : 'settlement';
    final result = await showDebtTransactionModal(
      context: context,
      party: widget.party,
      transactionKind: transactionKind,
    );

    if (result == true && mounted) {
      _reload();
    }
  }
}
