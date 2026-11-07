import 'package:flutter/widgets.dart';

/// Lightweight UI copy for the home dashboard. The selected locale is kept
/// in the screen state for this first UI refresh; persistence can be added later.
class VaultStrings {
  final bool isArabic;
  const VaultStrings(this.isArabic);

  static VaultStrings of(BuildContext context, bool isArabic) =>
      VaultStrings(isArabic);

  String get appName => isArabic ? 'الخزنة الآمنة' : 'Secure Vault';
  String get greeting => isArabic ? 'أهلاً بعودتك' : 'Welcome back';
  String get overview => isArabic ? 'نظرة عامة على خزنتك' : 'Your private space, at a glance';
  String get totalItems => isArabic ? 'إجمالي العناصر' : 'TOTAL ITEMS';
  String get favorites => isArabic ? 'المفضلة' : 'FAVORITES';
  String get categories => isArabic ? 'التصنيفات' : 'CATEGORIES';
  String get search => isArabic ? 'ابحث في المفاتيح والبطاقات والملاحظات...' : 'Search keys, cards, notes or tags...';
  String get recent => isArabic ? 'العناصر الأخيرة' : 'RECENT ITEMS';
  String get quickAccess => isArabic ? 'وصول سريع' : 'QUICK ACCESS';
  String get addItem => isArabic ? 'إضافة عنصر' : 'Add item';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get lock => isArabic ? 'قفل الخزنة' : 'Lock vault';
  String get noItems => isArabic ? 'خزنتك فارغة حتى الآن' : 'Your vault is empty';
  String get noItemsHint => isArabic ? 'ابدأ بإضافة بياناتك المهمة واحفظها في مكان واحد.' : 'Add your important details and keep them in one private place.';
  String get noResults => isArabic ? 'لا توجد نتائج مطابقة' : 'No matching items found';
  String get clearFilters => isArabic ? 'مسح عوامل التصفية' : 'Clear filters';
  String get language => isArabic ? 'EN' : 'ع';
  String get secureStorage => isArabic ? 'تخزين محلي مشفر' : 'Encrypted local storage';
  String get passwords => isArabic ? 'كلمات المرور' : 'Passwords';
  String get wifi => isArabic ? 'شبكات Wi-Fi' : 'Wi-Fi';
  String get security => isArabic ? 'الأمان' : 'Security';
  String get backup => isArabic ? 'النسخ الاحتياطي' : 'Backup';
}
