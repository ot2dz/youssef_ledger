// lib/core/utils/icon_utils.dart
import 'package:flutter/material.dart';

/// دالة مساعدة لتحويل iconCodePoint إلى IconData ثابت
/// تستخدم لحل مشكلة tree-shaking في البناء
IconData getIconFromCodePoint(int codePoint) {
  // قائمة الأيقونات الشائعة المستخدمة في التطبيق
  const Map<int, IconData> commonIcons = {
    // Material Icons الأساسية
    57785: Icons.shopping_cart,
    57786: Icons.shopping_bag,
    58332: Icons.restaurant,
    58727: Icons.local_gas_station,
    58732: Icons.local_grocery_store,
    58133: Icons.home,
    58394: Icons.school,
    57415: Icons.directions_car,
    57737: Icons.phone,
    58505: Icons.work,
    59064: Icons.category,
    58731: Icons.local_dining,
    58780: Icons.medical_services,
    58497: Icons.weekend,
    58882: Icons.sports_soccer,
    58384: Icons.savings,
    58117: Icons.hotel,
    58125: Icons.house,
    58291: Icons.payments,
    58293: Icons.person,
    58720: Icons.library_books,
    58915: Icons.train,
    59003: Icons.toys,
    59085: Icons.computer,
    59536: Icons.pets,
  };

  // إرجاع الأيقونة المطابقة أو أيقونة افتراضية
  return commonIcons[codePoint] ?? Icons.category;
}
