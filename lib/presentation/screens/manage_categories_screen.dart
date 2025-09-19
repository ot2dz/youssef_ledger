// lib/presentation/screens/manage_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/category.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ManageCategoriesScreenState createState() => ManageCategoriesScreenState();
}

class ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = DatabaseHelper.instance.getCategories('expense');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة الفئات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _showCategoryDialog(),
                tooltip: 'إضافة فئة جديدة',
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<Category>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('لا توجد فئات. قم بإضافة فئة جديدة.'),
              );
            }

            final categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: Icon(
                    IconData(
                      category.iconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                  ),
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showCategoryDialog(category: category),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteCategory(category.id!),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCategoryDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name);
    IconData? selectedIcon = isEditing
        ? IconData(category.iconCodePoint, fontFamily: 'MaterialIcons')
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'تعديل الفئة' : 'فئة جديدة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم الفئة'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text("الأيقونة: "),
                      const Spacer(),
                      if (selectedIcon != null) Icon(selectedIcon),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        child: const Text('اختر'),
                        onPressed: () async {
                          final picked = await showIconPicker(context);
                          if (picked != null) {
                            setDialogState(() {
                              selectedIcon = picked.data; // IconData
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FilledButton(
                  child: const Text('حفظ'),
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      // يمكنك إظهار رسالة خطأ هنا إذا أردت
                      return;
                    }

                    // 2. إذا لم يتم اختيار أيقونة، قم بتعيين أيقونة افتراضية
                    final finalIcon = selectedIcon ?? Icons.label_outline;

                    final newCategory = Category(
                      id: category?.id,
                      name: nameController.text,
                      iconCodePoint:
                          finalIcon.codePoint, // استخدم الأيقونة النهائية
                      type: 'expense',
                    );

                    if (isEditing) {
                      await DatabaseHelper.instance.updateCategory(newCategory);
                    } else {
                      await DatabaseHelper.instance.createCategory(newCategory);
                    }

                    if (mounted) {
                      _loadCategories(); // لتحديث القائمة
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCategory(int id) async {
    // يمكنك إضافة نافذة تأكيد هنا
    await DatabaseHelper.instance.deleteCategory(id);
    _loadCategories();
  }
}
