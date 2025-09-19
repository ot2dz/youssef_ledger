import 'package:flutter/material.dart';

/// أنماط الأزرار المشتركة للإجراءات في التطبيق
class ActionButtonStyles {
  // الألوان الأساسية
  static const Color redColor = Color(0xFFE53E3E);
  static const Color greenColor = Color(0xFF38A169);
  
  /// نمط الزر الأحمر للإجراءات مثل الإقراض والشراء
  static ButtonStyle get redActionStyle {
    return FilledButton.styleFrom(
      backgroundColor: redColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withOpacity(0.1);
          }
          return null;
        },
      ),
    );
  }
  
  /// نمط الزر الأخضر للإجراءات مثل الاستلام والتسديد
  static ButtonStyle get greenActionStyle {
    return FilledButton.styleFrom(
      backgroundColor: greenColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withOpacity(0.1);
          }
          return null;
        },
      ),
    );
  }
}