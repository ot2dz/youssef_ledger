# دليل إعداد Google Drive API وتسجيل الدخول

## المشكلة الحالية
عند الضغط على تسجيل الدخول إلى Google Drive، يظهر بريد إلكتروني تجريبي بدلاً من واجهة اختيار حساب Google الصحيحة.

## سبب المشكلة
- ملف `google-services.json` مفقود من مجلد `android/app/`
- لم يتم إعداد Google Cloud Console للمشروع
- لم يتم تفعيل Google Drive API

## خطوات الحل

### 1. إنشاء مشروع Google Cloud Console

1. اذهب إلى [Google Cloud Console](https://console.cloud.google.com/)
2. انقر على "Create Project" أو اختر مشروع موجود
3. اكتب اسم المشروع: `Youssef Fabric Ledger`
4. انقر على "Create"

### 2. تفعيل Google Drive API

1. في مشروع Google Cloud، اذهب إلى "APIs & Services" > "Library"
2. ابحث عن "Google Drive API"
3. انقر على "Enable"

### 3. إعداد OAuth Consent Screen

1. اذهب إلى "APIs & Services" > "OAuth consent screen"
2. اختر "External" (للاختبار)
3. املأ المعلومات المطلوبة:
   - App name: `Youssef Fabric Ledger`
   - User support email: بريدك الإلكتروني
   - Developer contact information: بريدك الإلكتروني
4. انقر على "Save and Continue"

### 4. إنشاء OAuth Client ID

1. اذهب إلى "APIs & Services" > "Credentials"
2. انقر على "Create Credentials" > "OAuth client ID"
3. اختر "Android"
4. اكتب اسم العميل: `Android Client`
5. Package name: `com.example.youssef_fabric_ledger`
6. للحصول على SHA-1 certificate fingerprint:

```bash
cd android
./gradlew signingReport
```

نسخ SHA-1 من قسم debug وألصقه في الحقل المطلوب

7. انقر على "Create"

### 5. تحميل google-services.json

1. بعد إنشاء OAuth client، اذهب إلى "APIs & Services" > "Credentials"
2. انقر على رمز التحميل بجانب Android OAuth client
3. احفظ الملف باسم `google-services.json`
4. ضع الملف في مجلد `android/app/`

### 6. تحديث build.gradle

1. افتح `android/build.gradle.kts`
2. أضف في قسم plugins:

```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```

3. افتح `android/app/build.gradle.kts`
4. أضف في أعلى الملف:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // أضف هذا السطر
}
```

### 7. إعادة تشغيل التطبيق

```bash
flutter clean
flutter pub get
flutter run
```

## نصائح إضافية

- تأكد من أن Package Name متطابق في كل من:
  - Google Cloud Console
  - `android/app/build.gradle.kts`
  - `pubspec.yaml`

- للاختبار، أضف بريدك الإلكتروني كـ Test User في OAuth consent screen

- بعد التطبيق في الإنتاج، غير OAuth consent screen إلى "Internal" أو "Published"

## تحقق من النجاح

بعد تطبيق الخطوات:
- عند الضغط على تسجيل الدخول، ستظهر واجهة اختيار حساب Google
- يمكن اختيار أي حساب Google مسجل في الجهاز
- التصريحات ستعمل بشكل صحيح مع Google Drive API

## استكشاف الأخطاء

### إذا ظهر خطأ "Sign in failed"
- تحقق من SHA-1 fingerprint
- تأكد من Package Name
- تحقق من تفعيل Google Drive API

### إذا لم تظهر واجهة اختيار الحساب
- تأكد من وجود ملف `google-services.json`
- تحقق من إضافة Google Services plugin
- أعد تشغيل التطبيق بعد `flutter clean`

## ملاحظات أمنية

- لا تضع ملف `google-services.json` في version control عام
- استخدم متغيرات البيئة للمفاتيح الحساسة في الإنتاج
- راجع أذونات OAuth بانتظام