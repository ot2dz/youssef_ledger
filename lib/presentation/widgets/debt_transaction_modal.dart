import 'package:flutter/material.dart';
import '../../data/models/debt_entry.dart';
import '../../data/models/party.dart';
import '../../core/enums.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/finance_provider.dart';

/// نموذج إضافة/تعديل معاملة دين مخصص لطرف معين
class DebtTransactionModal extends StatefulWidget {
  final Party party;
  final String
  transactionKind; // 'purchase_credit', 'payment', 'loan_out', 'settlement'
  final VoidCallback? onTransactionSaved;
  final DebtEntry? existingEntry; // للتعديل: معاملة موجودة

  const DebtTransactionModal({
    super.key,
    required this.party,
    required this.transactionKind,
    this.onTransactionSaved,
    this.existingEntry,
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
    // إذا كان هناك معاملة موجودة، استخدم بياناتها
    if (widget.existingEntry != null) {
      _amountController.text = widget.existingEntry!.amount.toStringAsFixed(2);
      _noteController.text = widget.existingEntry!.note ?? '';
      _selectedPaymentMethod = widget.existingEntry!.paymentMethod;
    } else {
      // تحديد الطريقة الافتراضية حسب نوع الطرف ونوع المعاملة
      _selectedPaymentMethod = _getDefaultPaymentMethod();
    }
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
        return PaymentMethod.cash; // الإقراض افتراضيًا نقدي (الأكثر شيوعًا)
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
    final isEditing = widget.existingEntry != null;
    final prefix = isEditing ? 'تعديل' : '';

    switch (widget.transactionKind) {
      case 'purchase_credit':
        return '${prefix.isNotEmpty ? "$prefix " : ""}شراء بالدين من ${widget.party.name}';
      case 'payment':
        return '${prefix.isNotEmpty ? "$prefix " : ""}تسديد دفعة لـ ${widget.party.name}';
      case 'loan_out':
        return '${prefix.isNotEmpty ? "$prefix " : ""}إقراض مبلغ لـ ${widget.party.name}';
      case 'settlement':
        return '${prefix.isNotEmpty ? "$prefix " : ""}استلام دفعة من ${widget.party.name}';
      default:
        return '${prefix.isNotEmpty ? "$prefix " : ""}معاملة مع ${widget.party.name}';
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
    final isEditing = widget.existingEntry != null;

    if (isEditing) {
      return 'حفظ التعديلات';
    }

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

  /// حفظ أو تعديل المعاملة في قاعدة البيانات
  void _saveTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.existingEntry != null;

      final debtEntry = DebtEntry(
        id: isEditing ? widget.existingEntry!.id : null,
        date: isEditing ? widget.existingEntry!.date : DateTime.now(),
        partyId: widget.party.id!,
        kind: widget.transactionKind,
        amount: double.parse(_amountController.text),
        paymentMethod: _selectedPaymentMethod,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        createdAt: isEditing ? widget.existingEntry!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        // تعديل معاملة موجودة
        await context.read<FinanceProvider>().updateDebtTransaction(debtEntry);
      } else {
        // إضافة معاملة جديدة
        await context.read<FinanceProvider>().addDebtTransaction(debtEntry);
      }

      if (mounted) {
        // تحديث البيانات في المزود
        context.read<FinanceProvider>().fetchFinancialDataForSelectedDate();

        // تحديث البيانات في الشاشة الحالية
        widget.onTransactionSaved?.call();

        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'تم تعديل ${_getSuccessMessage()} بنجاح'
                  : 'تم حفظ ${_getSuccessMessage()} بنجاح',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء ${widget.existingEntry != null ? "التعديل" : "الحفظ"}: $e',
            ),
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

/// دالة مساعدة لفتح نموذج معاملة الدين (إضافة/تعديل)
Future<bool?> showDebtTransactionModal({
  required BuildContext context,
  required Party party,
  required String transactionKind,
  VoidCallback? onTransactionSaved,
  DebtEntry? existingEntry, // للتعديل
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DebtTransactionModal(
      party: party,
      transactionKind: transactionKind,
      onTransactionSaved: onTransactionSaved,
      existingEntry: existingEntry,
    ),
  );
}
