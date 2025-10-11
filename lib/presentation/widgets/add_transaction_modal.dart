import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/income.dart';
import '../../data/models/drawer_snapshot.dart';
import '../../data/local/database_helper.dart';
import '../../logic/providers/finance_provider.dart';
import '../../data/models/category.dart';
import '../../core/formatters/date_formatters.dart';
import '../../core/utils/icon_utils.dart';

class AddTransactionModal extends StatefulWidget {
  // --- ✅ الإضافة هنا ---
  final Expense? expenseToEdit; // مصروف اختياري للتعديل

  const AddTransactionModal({this.expenseToEdit, super.key});
  // --- نهاية الإضافة ---

  @override
  AddTransactionModalState createState() => AddTransactionModalState();
}

class AddTransactionModalState extends State<AddTransactionModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // --- ✅ التعديل هنا: تقليل عدد التبويبات إلى 3 ---
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            // شريط التبويبات
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                // --- ✅ التعديل هنا: إزالة تبويب "ديون" ---
                Tab(text: "مصروف", icon: Icon(Icons.payment)),
                Tab(text: "دخل", icon: Icon(Icons.attach_money)),
                Tab(text: "درج", icon: Icon(Icons.inbox_outlined)),
              ],
            ),
            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- ✅ التعديل هنا: إزالة واجهة "ديون" ---
                  ExpenseForm(expenseToEdit: widget.expenseToEdit),
                  const IncomeForm(),
                  const DrawerForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// نموذج المصروفات

class ExpenseForm extends StatefulWidget {
  // --- ✅ استقبال المصروف هنا ---
  final Expense? expenseToEdit;
  const ExpenseForm({this.expenseToEdit, super.key});

  @override
  ExpenseFormState createState() => ExpenseFormState();
}

class ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // --- ✅ تعديل المتغيرات ---
  late DateTime _selectedDate;
  late TransactionSource _selectedSource;
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoading = false;
  late bool _isEditing; // متغير لتحديد وضع التعديل

  @override
  void initState() {
    super.initState();
    _isEditing = widget.expenseToEdit != null;
    _initializeFields();
    _loadCategories();
  }

  // --- ✅ دالة جديدة لتهيئة الحقول ---
  void _initializeFields() {
    if (_isEditing) {
      final expense = widget.expenseToEdit!;
      _amountController.text = expense.amount.toString();
      _noteController.text = expense.note ?? '';
      _selectedDate = expense.date;
      _selectedSource = expense.source;
      _selectedCategoryId = expense.categoryId;
    } else {
      _selectedDate = DateTime.now();
      _selectedSource = TransactionSource.cash;
    }
  }

  /// تحميل فئات المصروفات
  Future<void> _loadCategories() async {
    try {
      final categories = await DatabaseHelper.instance.getCategories('expense');
      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في تحميل الفئات: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حقل المبلغ
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // اختيار الفئة
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'الفئة',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(getIconFromCodePoint(category.iconCodePoint)),
                      SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'يرجى اختيار فئة';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // اختيار المصدر
            DropdownButtonFormField<TransactionSource>(
              value: _selectedSource,
              decoration: const InputDecoration(
                labelText: 'المصدر',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TransactionSource.cash,
                  child: Text('نقدي'),
                ),
                DropdownMenuItem(
                  value: TransactionSource.drawer,
                  child: Text('درج'),
                ),
                DropdownMenuItem(
                  value: TransactionSource.bank,
                  child: Text('بنك'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSource = value!;
                });
              },
            ),
            SizedBox(height: 16),

            // اختيار التاريخ
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('التاريخ'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey),
              ),
            ),
            SizedBox(height: 16),

            // حقل الملاحظة
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),

            // زر الحفظ
            ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('حفظ المصروف'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// اختيار التاريخ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- ✅ تعديل دالة الحفظ ---
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // إنشاء كائن Expense بناءً على وضع الإضافة أو التعديل
      final expense = Expense(
        id: _isEditing
            ? widget.expenseToEdit!.id
            : null, // استخدم الـ ID القديم عند التعديل
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId!,
        source: _selectedSource,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        createdAt: _isEditing
            ? widget.expenseToEdit!.createdAt
            : DateTime.now(), // احتفظ بتاريخ الإنشاء الأصلي
      );

      // Use the provider to save the expense
      await Provider.of<FinanceProvider>(
        context,
        listen: false,
      ).addOrUpdateExpense(expense);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ المصروف بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في حفظ المصروف: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

// نموذج الدخل
class IncomeForm extends StatefulWidget {
  const IncomeForm({super.key});

  @override
  IncomeFormState createState() => IncomeFormState();
}

class IncomeFormState extends State<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionSource _selectedSource =
      TransactionSource.cash; // تغيير من drawer إلى cash
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حقل المبلغ
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // اختيار المصدر
            DropdownButtonFormField<TransactionSource>(
              value: _selectedSource,
              decoration: const InputDecoration(
                labelText: 'المصدر',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TransactionSource.cash,
                  child: Text('نقداً'),
                ),
                DropdownMenuItem(
                  value: TransactionSource.drawer,
                  child: Text('درج'),
                ),
                DropdownMenuItem(
                  value: TransactionSource.bank,
                  child: Text('بنك'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSource = value!;
                });
              },
            ),
            SizedBox(height: 16),

            // اختيار التاريخ
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('التاريخ'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey),
              ),
            ),
            SizedBox(height: 16),

            // حقل الملاحظة
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),

            // زر الحفظ
            ElevatedButton(
              onPressed: _isLoading ? null : _saveIncome,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('حفظ الدخل'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// اختيار التاريخ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// حفظ الدخل
  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final income = Income(
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        source: _selectedSource,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        createdAt: DateTime.now(),
      );

      // Use the new addIncome method which handles cash balance updates
      final financeProvider = Provider.of<FinanceProvider>(
        context,
        listen: false,
      );
      await financeProvider.addIncome(income);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم حفظ الدخل بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في حفظ الدخل: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

// نموذج الديون

// داخل ملف add_transaction_modal.dart، استبدل الكلاسات القديمة بهذا
class DrawerForm extends StatefulWidget {
  const DrawerForm({super.key});

  @override
  DrawerFormState createState() => DrawerFormState();
}

class DrawerFormState extends State<DrawerForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  // متغير لتخزين نوع اللقطة المختارة ('start' or 'end')
  SnapshotType _selectedType = SnapshotType.start;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // حفظ لقطة الدرج
  Future<void> _saveSnapshot() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.parse(_amountController.text);
    final note = _noteController.text;

    final snapshot = DrawerSnapshot(
      date: _selectedDate,
      type: _selectedType,
      cashAmount: amount,
      note: note.isNotEmpty ? note : null,
      createdAt: DateTime.now(),
    );

    await DatabaseHelper.instance.saveDrawerSnapshot(snapshot);

    if (mounted) {
      // لا تحتاج لاستدعاء الـ Provider هنا لأننا سنقوم بذلك في main_layout

      // --- التعديل هنا ---
      Navigator.of(context).pop(true); // أرجع 'true' للإشارة إلى النجاح
      // --- نهاية التعديل ---

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ رصيد ${_selectedType == SnapshotType.start ? 'البداية' : 'النهاية'} بنجاح',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "تسجيل رصيد الدرج",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // 1. محدد التاريخ
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'التاريخ',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(DateFormatters.formatFullDateArabic(_selectedDate)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // 2. حقل المبلغ
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              suffixText: 'د.ج',
              prefixIcon: Icon(Icons.money),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  double.tryParse(value) == null) {
                return 'الرجاء إدخال مبلغ صحيح';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 3. القائمة المنسدلة (بداية / نهاية)
          DropdownButtonFormField<SnapshotType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'نوع الرصيد',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              prefixIcon: Icon(Icons.sync_alt),
            ),
            items: const [
              DropdownMenuItem(
                value: SnapshotType.start,
                child: Text('رصيد بداية اليوم'),
              ),
              DropdownMenuItem(
                value: SnapshotType.end,
                child: Text('رصيد نهاية اليوم'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // 4. حقل الملاحظات
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'ملاحظة (اختياري)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
          ),
          const SizedBox(height: 32),

          // 5. زر الحفظ
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('حفظ', style: TextStyle(fontSize: 16)),
            onPressed: _saveSnapshot,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
