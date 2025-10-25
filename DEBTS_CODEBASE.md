# 📁 قاعدة أكواد نظام الديون (الأشخاص والموردين)

> تجميع شامل لجميع الملفات المسؤولة عن إدارة الديون في التطبيق

---

## 📋 جدول المحتويات

1. [الشاشات (Screens)](#1-الشاشات-screens)
2. [الويدجتات (Widgets)](#2-الويدجتات-widgets)
3. [النماذج (Models)](#3-النماذج-models)
4. [المساعدات (Utilities)](#4-المساعدات-utilities)

---

## 1. الشاشات (Screens)

### 📄 `lib/presentation/screens/debts_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';
import '../widgets/parties_list_view.dart';
import '../widgets/debts_stats_card.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _runDataCleanup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runDataCleanup() async {
    try {
      // Ensure SQL views exist (in case migration was missed)
      await DatabaseHelper.instance.ensureViewsExist();

      await DatabaseHelper.instance.fixPartyTypes();
      await DatabaseHelper.instance.logInvalidPartyTypes();
    } catch (e) {
      debugPrint('[DebtsScreen] Error during data cleanup: $e');
    }
  }

  /// Show dialog to add a new party based on current tab
  void _showAddPartyDialog() async {
    final currentRole = _tabController.index == 0
        ? PartyRole.person
        : PartyRole.vendor;
    final roleText = currentRole == PartyRole.person ? 'شخص' : 'مورد';

    final nameController = TextEditingController();
    final newPartyName = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                currentRole == PartyRole.person
                    ? Icons.person_add
                    : Icons.business_outlined,
                color: const Color(0xFF6366F1),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'إضافة $roleText جديد',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "اسم ال$roleText",
              prefixIcon: Icon(
                currentRole == PartyRole.person ? Icons.person : Icons.business,
                color: const Color(0xFF6366F1),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(nameController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إضافة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (newPartyName != null && newPartyName.isNotEmpty) {
      debugPrint(
        '[UI-DEBUG] Adding new party: $newPartyName, Role: $currentRole',
      );

      try {
        if (currentRole == PartyRole.vendor) {
          await DatabaseHelper.instance.createVendor(newPartyName);
        } else {
          await DatabaseHelper.instance.createPerson(newPartyName);
        }
        debugPrint(
          '[UI] Added $roleText: $newPartyName → auto-refresh via DbBus',
        );
      } catch (e) {
        debugPrint('[ERROR] Failed to add $roleText: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'الديون',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF6366F1), // Modern blue color
            foregroundColor: Colors.white,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    debugPrint(
                      '[UI] Opened tab: ${index == 0 ? 'persons' : 'vendors'}',
                    );
                  },
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  labelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: _tabController.index == 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              const Text('أشخاص'),
                            ],
                          );
                        },
                      ),
                    ),
                    Tab(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                size: 20,
                                color: _tabController.index == 1
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              const Text('موردون'),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Stats card - تصميم مدمج
              const DebtsStatsCard(),
              // Tabs content
              Expanded(
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    return IndexedStack(
                      index: _tabController.index,
                      children: [
                        // Persons tab
                        PartiesList(role: PartyRole.person),
                        // Vendors tab
                        PartiesList(role: PartyRole.vendor),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final isPersonsTab = _tabController.index == 0;
              return FloatingActionButton.extended(
                onPressed: _showAddPartyDialog,
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                label: Text(
                  isPersonsTab ? 'إضافة شخص' : 'إضافة مورد',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                icon: Icon(
                  isPersonsTab ? Icons.person_add : Icons.business_outlined,
                  size: 22,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

**المسؤوليات:**
- الشاشة الرئيسية لقسم الديون
- إدارة تبويبين: الأشخاص والموردين
- عرض ملخص الديون
- حوار إضافة طرف جديد

---

### 📄 `lib/presentation/screens/party_details_screen.dart`

> ⚠️ **ملف كبير جدًا - يحتوي على 607 سطر**

**الوظائف الرئيسية:**
- عرض تفاصيل الطرف (شخص/مورد)
- حساب الرصيد الحالي (`_computeBalance`)
- عرض تاريخ جميع المعاملات
- أزرار الإجراءات السفلية (شراء، تسديد، إقراض، استلام)
- تعديل وحذف الطرف

**الدوال الأساسية:**
- `_computeBalance()`: حساب الرصيد من المعاملات مع فلترة حسب paymentMethod
- `_buildBalanceCard()`: عرض بطاقة الرصيد مع الألوان المناسبة
- `_buildTransactionCard()`: عرض كل معاملة بتفاصيلها
- `_handleFirstAction()`, `_handleSecondAction()`: معالجة الأزرار السفلية

---

## 2. الويدجتات (Widgets)

### 📄 `lib/presentation/widgets/parties_list_view.dart`

> ⚠️ **ملف كبير جدًا - يحتوي على 864 سطر**

**الوظائف الرئيسية:**
- قائمة الأطراف (أشخاص/موردين) مع الإحصائيات
- البحث والفلترة
- التحديث التلقائي عبر `DbBus`
- أزرار الإجراءات السريعة لكل طرف

**الفئات:**
- `PartyWithStats`: نموذج يجمع Party مع الإحصائيات
- `PartiesList`: القائمة الرئيسية مع keep-alive
- `PartyBalanceCard`: بطاقة عرض طرف واحد

**الميزات:**
- AutomaticKeepAliveClientMixin لحفظ حالة التبويب
- StreamSubscription مع DbBus للتحديث التلقائي
- فلترة متقدمة (الكل، لديهم رصيد، بدون رصيد، نشاط حديث)
- بحث بالاسم ورقم الهاتف

---

### 📄 `lib/presentation/widgets/debt_transaction_modal.dart`

```dart
import 'package:flutter/material.dart';
import '../../data/models/debt_entry.dart';
import '../../data/models/party.dart';
import '../../core/enums.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/finance_provider.dart';

/// نموذج إضافة معاملة دين مخصص لطرف معين
class DebtTransactionModal extends StatefulWidget {
  final Party party;
  final String
  transactionKind; // 'purchase_credit', 'payment', 'loan_out', 'settlement'
  final VoidCallback? onTransactionSaved;

  const DebtTransactionModal({
    super.key,
    required this.party,
    required this.transactionKind,
    this.onTransactionSaved,
  });

  @override
  State<DebtTransactionModal> createState() => _DebtTransactionModalState();
}

class _DebtTransactionModalState extends State<DebtTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late PaymentMethod _selectedPaymentMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // تحديد الطريقة الافتراضية حسب نوع الطرف ونوع المعاملة
    _selectedPaymentMethod = _getDefaultPaymentMethod();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// تحديد طريقة الدفع الافتراضية حسب نوع الطرف والمعاملة
  PaymentMethod _getDefaultPaymentMethod() {
    // للموردين: حسب نوع المعاملة
    if (widget.party.role == PartyRole.vendor) {
      switch (widget.transactionKind) {
        case 'purchase_credit':
          return PaymentMethod.credit; // الشراء من المورد يكون آجل افتراضياً
        case 'payment':
          return PaymentMethod.cash; // التسديد للمورد يكون نقداً افتراضياً
        default:
          return PaymentMethod.cash;
      }
    }

    // للأشخاص: حسب نوع المعاملة
    switch (widget.transactionKind) {
      case 'loan_out':
        return PaymentMethod.credit; // الإقراض هو دين (آجل)
      case 'settlement':
        return PaymentMethod.cash; // الاستلام عادة نقداً
      case 'purchase_credit':
      case 'payment':
        return PaymentMethod.credit; // الشراء والدفع عادة آجل
      default:
        return PaymentMethod.cash;
    }
  }

  /// الحصول على عنوان النموذج بناءً على نوع المعاملة
  String get _getTitle {
    switch (widget.transactionKind) {
      case 'purchase_credit':
        return 'شراء بالدين من ${widget.party.name}';
      case 'payment':
        return 'تسديد دفعة لـ ${widget.party.name}';
      case 'loan_out':
        return 'إقراض مبلغ لـ ${widget.party.name}';
      case 'settlement':
        return 'استلام دفعة من ${widget.party.name}';
      default:
        return 'معاملة مع ${widget.party.name}';
    }
  }

  /// الحصول على أيقونة النموذج بناءً على نوع المعاملة
  IconData get _getIcon {
    switch (widget.transactionKind) {
      case 'purchase_credit':
        return Icons.shopping_cart;
      case 'payment':
        return Icons.payment;
      case 'loan_out':
        return Icons.arrow_upward;
      case 'settlement':
        return Icons.arrow_downward;
      default:
        return Icons.account_balance_wallet;
    }
  }

  /// الحصول على لون النموذج بناءً على نوع المعاملة
  Color get _getColor {
    switch (widget.transactionKind) {
      case 'purchase_credit':
      case 'loan_out':
        return Colors.red.shade600; // زيادة الدين
      case 'payment':
      case 'settlement':
        return Colors.green.shade600; // تقليل الدين
      default:
        return Colors.blue.shade600;
    }
  }

  /// الحصول على نص الزر بناءً على نوع المعاملة
  String get _getButtonText {
    switch (widget.transactionKind) {
      case 'purchase_credit':
        return 'تسجيل الشراء';
      case 'payment':
        return 'تسجيل التسديد';
      case 'loan_out':
        return 'تسجيل الإقراض';
      case 'settlement':
        return 'تسجيل الاستلام';
      default:
        return 'حفظ المعاملة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // مقبض السحب
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // العنوان مع الأيقونة
              Row(
                children: [
                  Icon(_getIcon, color: _getColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // حقل المبلغ
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixText: 'د.ج',
                  prefixIcon: Icon(Icons.money, color: _getColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال المبلغ';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'الرجاء إدخال مبلغ صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل طريقة الدفع
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'طريقة الدفع',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: PaymentMethod.values.map((method) {
                  String displayName;
                  IconData icon;
                  switch (method) {
                    case PaymentMethod.cash:
                      displayName = 'نقداً';
                      icon = Icons.money;
                      break;
                    case PaymentMethod.credit:
                      displayName = 'آجل';
                      icon = Icons.schedule;
                      break;
                    case PaymentMethod.bank:
                      displayName = 'بنكي';
                      icon = Icons.account_balance;
                      break;
                  }
                  return DropdownMenuItem(
                    value: method,
                    child: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (PaymentMethod? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // حقل الملاحظات
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 3,
              ),
              const Spacer(),

              // زر الحفظ
              FilledButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_getIcon),
                label: Text(
                  _isLoading ? 'جاري الحفظ...' : _getButtonText,
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: _isLoading ? null : _saveTransaction,
                style: FilledButton.styleFrom(
                  backgroundColor: _getColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// حفظ المعاملة في قاعدة البيانات
  void _saveTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final debtEntry = DebtEntry(
        date: DateTime.now(),
        partyId: widget.party.id!,
        kind: widget.transactionKind,
        amount: double.parse(_amountController.text),
        paymentMethod: _selectedPaymentMethod,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        createdAt: DateTime.now(),
      );

      await context.read<FinanceProvider>().addDebtTransaction(debtEntry);

      if (mounted) {
        // تحديث البيانات في المزود
        context.read<FinanceProvider>().fetchFinancialDataForSelectedDate();

        // تحديث البيانات في الشاشة الحالية
        widget.onTransactionSaved?.call();

        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ ${_getSuccessMessage()} بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// الحصول على رسالة النجاح بناءً على نوع المعاملة
  String _getSuccessMessage() {
    switch (widget.transactionKind) {
      case 'purchase_credit':
        return 'معاملة الشراء';
      case 'payment':
        return 'معاملة التسديد';
      case 'loan_out':
        return 'معاملة الإقراض';
      case 'settlement':
        return 'معاملة الاستلام';
      default:
        return 'المعاملة';
    }
  }
}

/// دالة مساعدة لفتح نموذج معاملة الدين
Future<bool?> showDebtTransactionModal({
  required BuildContext context,
  required Party party,
  required String transactionKind,
  VoidCallback? onTransactionSaved,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DebtTransactionModal(
      party: party,
      transactionKind: transactionKind,
      onTransactionSaved: onTransactionSaved,
    ),
  );
}
```

**المسؤوليات:**
- نافذة منبثقة لإضافة معاملة دين
- اختيار طريقة الدفع (نقدي، آجل، بنكي)
- القيم الافتراضية الذكية حسب نوع المعاملة
- التحقق من صحة البيانات

---

### 📄 `lib/presentation/widgets/debts_stats_card.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/database_helper.dart';
import '../../data/local/db_bus.dart';

class DebtsStatsCard extends StatefulWidget {
  const DebtsStatsCard({super.key});

  @override
  State<DebtsStatsCard> createState() => _DebtsStatsCardState();
}

class _DebtsStatsCardState extends State<DebtsStatsCard> {
  double _receivableTotal = 0.0;
  double _payableTotal = 0.0;
  bool _isLoading = true;
  late StreamSubscription<void> _dbSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to database changes for auto-refresh
    _dbSubscription = DbBus.instance.stream.listen((_) {
      debugPrint('[UI] DbBus event → DebtsStatsCard refresh');
      _loadStats();
    });

    _loadStats();
  }

  @override
  void dispose() {
    _dbSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Get receivable total (money owed by persons)
      final receivableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM (
          SELECT 
            de.partyId,
            SUM(CASE 
              -- المعاملات التي تُنشئ ديون: فقط الآجلة
              WHEN (de.kind = 'purchase_credit' OR de.kind = 'loan_out') AND de.paymentMethod = 'credit' THEN de.amount
              -- المعاملات التي تُسدد ديون: بأي طريقة دفع
              WHEN (de.kind = 'payment' OR de.kind = 'settlement') THEN -de.amount
              ELSE 0
            END) as balance
          FROM debt_entries de
          JOIN parties p ON de.partyId = p.id
          WHERE p.type = 'person'
          GROUP BY de.partyId
          HAVING balance > 0
        )
      ''');

      // Get payable total (money owed to vendors)
      final payableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM (
          SELECT 
            de.partyId,
            SUM(CASE 
              -- المعاملات التي تُنشئ ديون: فقط الآجلة
              WHEN (de.kind = 'purchase_credit' OR de.kind = 'loan_out') AND de.paymentMethod = 'credit' THEN de.amount
              -- المعاملات التي تُسدد ديون: بأي طريقة دفع
              WHEN (de.kind = 'payment' OR de.kind = 'settlement') THEN -de.amount
              ELSE 0
            END) as balance
          FROM debt_entries de
          JOIN parties p ON de.partyId = p.id
          WHERE p.type = 'vendor'
          GROUP BY de.partyId
          HAVING balance > 0
        )
      ''');

      setState(() {
        _receivableTotal = (receivableResult.first['total'] as num).toDouble();
        _payableTotal = (payableResult.first['total'] as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DebtsStatsCard] Error loading stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0 د.ج';
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} د.ج';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'ملخص الديون:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CompactStatCard(
                  title: 'لك',
                  value: _formatAmount(_receivableTotal),
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _CompactStatCard(
                  title: 'عليك',
                  value: _formatAmount(_payableTotal),
                  icon: Icons.trending_down_rounded,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

**المسؤوليات:**
- بطاقة ملخص الديون المدمجة
- إجمالي الديون لك (من الأشخاص)
- إجمالي الديون عليك (للموردين)
- التحديث التلقائي عبر DbBus

---

## 3. النماذج (Models)

### 📄 `lib/data/models/party.dart`

```dart
// lib/data/models/party.dart

/// Enum representing the role of a party in the system
enum PartyRole {
  person,
  vendor;

  /// Convert role to database string representation
  String toDbString() {
    switch (this) {
      case PartyRole.person:
        return 'person';
      case PartyRole.vendor:
        return 'vendor';
    }
  }

  /// Parse role from database string representation
  static PartyRole? fromDbString(String? dbString) {
    if (dbString == null) return null;
    final normalized = dbString.trim().toLowerCase();
    switch (normalized) {
      case 'person':
        return PartyRole.person;
      case 'vendor':
        return PartyRole.vendor;
      default:
        return null;
    }
  }
}

class Party {
  // Legacy constants for backward compatibility during migration
  static const String kVendor = 'vendor';
  static const String kPerson = 'person';

  final int? id;
  final String name;
  final PartyRole role; // Use enum instead of string
  final String? phone;

  Party({this.id, required this.name, required this.role, this.phone});

  factory Party.vendor(String name, {String? phone}) =>
      Party(name: name.trim(), role: PartyRole.vendor, phone: phone);

  factory Party.person(String name, {String? phone}) =>
      Party(name: name.trim(), role: PartyRole.person, phone: phone);

  /// Legacy type getter for backward compatibility during migration
  String get type => role.toDbString();

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': role.toDbString(), 'phone': phone};
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    final typeString = (map['type'] as String).trim().toLowerCase();

    // Parse role with validation and fallback
    final parsedRole = PartyRole.fromDbString(typeString);
    final validRole =
        parsedRole ?? PartyRole.person; // Default to person if invalid

    // Debug assertion in development
    assert(
      parsedRole != null,
      'Invalid party type "$typeString" found in database. Defaulting to person.',
    );

    return Party(
      id: map['id'],
      name: map['name'],
      role: validRole,
      phone: map['phone'],
    );
  }

  Party copyWith({int? id, String? name, PartyRole? role, String? phone}) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
    );
  }
}
```

**المسؤوليات:**
- نموذج الطرف (شخص/مورد)
- PartyRole enum للتحكم الآمن في الأنواع
- تحويل من/إلى قاعدة البيانات

---

### 📄 `lib/data/models/debt_entry.dart`

```dart
// lib/data/models/debt_entry.dart
import 'package:youssef_fabric_ledger/core/enums.dart';

class DebtEntry {
  final int? id;
  final DateTime date;
  final int partyId;
  final String kind; // 'purchase_credit', 'payment', 'loan_out', 'settlement'
  final double amount;
  final PaymentMethod paymentMethod; // طريقة الدفع
  final String? note;
  final DateTime createdAt;

  DebtEntry({
    this.id,
    required this.date,
    required this.partyId,
    required this.kind,
    required this.amount,
    this.paymentMethod = PaymentMethod.credit, // افتراضياً آجل
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'partyId': partyId,
      'kind': kind,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DebtEntry.fromMap(Map<String, dynamic> map) {
    return DebtEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      partyId: map['partyId'] as int,
      kind: map['kind'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.byName(
        map['paymentMethod'] as String? ?? 'credit',
      ),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  DebtEntry copyWith({
    int? id,
    DateTime? date,
    int? partyId,
    String? kind,
    double? amount,
    PaymentMethod? paymentMethod,
    String? note,
    DateTime? createdAt,
  }) {
    return DebtEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      partyId: partyId ?? this.partyId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

**المسؤوليات:**
- نموذج معاملة الديون
- أنواع المعاملات: شراء بالآجل، تسديد، إقراض، استلام
- طرق الدفع: نقدي، آجل، بنكي

---

## 4. المساعدات (Utilities)

### 📄 `lib/data/local/db_bus.dart`

```dart
// lib/data/local/db_bus.dart
import 'dart:async';

/// Simple event bus for database change notifications
///
/// This utility allows UI components to listen for database changes
/// and refresh their data accordingly, ensuring consistency across the app.
class DbBus {
  static final DbBus instance = DbBus._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  DbBus._();

  /// Stream of database change events
  Stream<void> get stream => _controller.stream;

  /// Notify all listeners that the database has changed
  ///
  /// Call this after any insert, update, or delete operation
  /// to trigger UI refreshes.
  void bump() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  /// Close the stream controller (call during app shutdown)
  void dispose() {
    _controller.close();
  }
}
```

**المسؤوليات:**
- نظام إشعارات تغييرات قاعدة البيانات
- StreamController للبث المتعدد
- التحديث التلقائي للواجهة عند أي تغيير

---

### 📄 `lib/core/enums.dart` (جزئي)

```dart
enum PaymentMethod {
  cash,   // نقدي
  credit, // آجل
  bank    // بنكي
}
```

---

## 📊 الدوال الرئيسية في database_helper.dart

> ⚠️ الملف كبير جدًا، هنا قائمة بأهم الدوال المتعلقة بالديون:

### دوال الأطراف (Parties):
- `createPerson(String name)` - إضافة شخص جديد
- `createVendor(String name)` - إضافة مورد جديد
- `getPersons()` - جلب جميع الأشخاص
- `getVendors()` - جلب جميع الموردين
- `updateParty(Party party)` - تحديث طرف
- `deleteParty(int id)` - حذف طرف

### دوال معاملات الديون:
- `createDebtEntry(DebtEntry entry)` - إضافة معاملة دين (+ DbBus.bump())
- `getDebtEntriesForParty(int partyId)` - جلب معاملات طرف معين
- `updateDebtEntry(DebtEntry entry)` - تحديث معاملة
- `deleteDebtEntry(int id)` - حذف معاملة

### دوال الإحصائيات:
- `getPartyBalance(int partyId)` - حساب رصيد طرف واحد
- `getPartyStats(int partyId)` - إحصائيات طرف واحد
- `getAllPartiesStats(PartyRole role)` - إحصائيات جميع الأطراف (استعلام محسّن)
- `getTotalDebtsForVendors()` - إجمالي ديون الموردين
- `getTotalDebtsForPersons()` - إجمالي ديون الأشخاص

---

## 🔄 تدفق البيانات والتحديث التلقائي

```
┌─────────────────────────────────────────┐
│  إضافة/تعديل/حذف معاملة دين           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  DatabaseHelper.createDebtEntry()        │
│  → DbBus.instance.bump()                 │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  StreamController.add(null)              │
└──────────────┬───────────────────────────┘
               │
               ├─────────────────┬──────────────────┬─────────────────┐
               │                 │                  │                 │
               ▼                 ▼                  ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ PartiesList  │  │ DebtsStats   │  │ PartyDetails │  │ HomeScreen   │
    │ _loadParties │  │ _loadStats   │  │ _reload      │  │ etc...       │
    └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

---

## ✅ النقاط الحرجة في المنطق

### 1. حساب الرصيد:
```dart
// المعاملات التي تُنشئ ديون: فقط الآجلة
if (kind == 'purchase_credit' || kind == 'loan_out') 
   && paymentMethod == 'credit' → balance += amount

// المعاملات التي تُسدد ديون: بأي طريقة دفع
if (kind == 'payment' || kind == 'settlement') 
   → balance -= amount
```

### 2. الألوان حسب النوع:
```dart
// للموردين:
isPositive (رصيد +) → أحمر (مستحق له)
isNegative (رصيد -) → أخضر (مستحق منه)

// للأشخاص:
isPositive (رصيد +) → أخضر (مستحق منه)
isNegative (رصيد -) → أحمر (مستحق له)
```

### 3. طرق الدفع الافتراضية:
```dart
// للموردين:
purchase_credit → credit (آجل)
payment → cash (نقدي)

// للأشخاص:
loan_out → credit (آجل)
settlement → cash (نقدي)
```

---

## 📝 ملاحظات مهمة

1. **التحديث التلقائي**: جميع الويدجتات تستمع لـ `DbBus` للتحديث الفوري
2. **Keep-Alive**: `PartiesList` يحافظ على حالته عند التنقل بين التبويبات
3. **الفلترة الذكية**: استعلامات SQL محسّنة مع CASE statements
4. **التحقق من الأنواع**: استخدام Enum بدلاً من String للأمان
5. **الاتساق**: نفس المنطق في UI والـ Database

---

## 🎯 الخلاصة

هذا النظام يوفر:
- ✅ إدارة كاملة للديون (أشخاص وموردين)
- ✅ تحديث تلقائي للواجهة
- ✅ فلترة وبحث متقدمين
- ✅ إحصائيات فورية ودقيقة
- ✅ تجربة مستخدم سلسة وسريعة

---

**آخر تحديث:** 24 أكتوبر 2025
**الإصدار:** 1.0.0
