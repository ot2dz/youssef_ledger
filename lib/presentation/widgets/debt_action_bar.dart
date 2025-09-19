import 'package:flutter/material.dart';
import '../theme/action_button_styles.dart';

/// شريط الإجراءات السفلي للديون - قابل لإعادة الاستخدام
class DebtActionBar extends StatelessWidget {
  /// دالة الضغط على الزر الأول (إقراض للأشخاص أو شراء للموردين)
  final VoidCallback onFirstActionPressed;
  
  /// دالة الضغط على الزر الثاني (استلام للأشخاص أو تسديد للموردين)
  final VoidCallback onSecondActionPressed;
  
  /// هل الطرف مورد؟ (لتحديد نوع الأزرار)
  final bool isVendor;
  
  const DebtActionBar({
    super.key,
    required this.onFirstActionPressed,
    required this.onSecondActionPressed,
    required this.isVendor,
  });
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // الزر الأول (أحمر)
            Expanded(
              child: FilledButton.icon(
                onPressed: onFirstActionPressed,
                style: ActionButtonStyles.redActionStyle,
                icon: Icon(
                  isVendor ? Icons.shopping_cart : Icons.arrow_upward,
                  size: 20,
                ),
                label: Text(isVendor ? 'شراء' : 'إقراض'),
              ),
            ),
            
            // مسافة بين الأزرار
            const SizedBox(width: 12),
            
            // الزر الثاني (أخضر)
            Expanded(
              child: FilledButton.icon(
                onPressed: onSecondActionPressed,
                style: ActionButtonStyles.greenActionStyle,
                icon: Icon(
                  isVendor ? Icons.payment : Icons.arrow_downward,
                  size: 20,
                ),
                label: Text(isVendor ? 'تسديد' : 'استلام'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}