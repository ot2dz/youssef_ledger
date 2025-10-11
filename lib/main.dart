import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/logic/providers/date_provider.dart';
import 'package:youssef_fabric_ledger/logic/providers/finance_provider.dart';
import 'package:youssef_fabric_ledger/presentation/screens/app_wrapper.dart';
import 'package:youssef_fabric_ledger/presentation/theme/app_theme.dart';

// This callback is executed in a separate isolate when the background task runs.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // TODO: Implement the actual backup logic by calling your BackupService.
    // final backupService = BackupService();
    // await backupService.performBackup();
    print("Native called background task: $task"); // For debugging
    return Future.value(true);
  });
}

void main() async {
  // Ensure that plugin services are initialized so that `Workmanager` can work.
  WidgetsFlutterBinding.ensureInitialized();

  // Run a one-time diagnostic to check for invalid party types in the database.
  await DatabaseHelper.instance.logInvalidPartyTypes();

  // Clean up duplicate categories on app startup
  try {
    await DatabaseHelper.instance.cleanupDuplicateData();
    print('✅ تم تنظيف البيانات المكررة بنجاح');
  } catch (e) {
    print('⚠️ تعذر تنظيف البيانات المكررة: $e');
  }

  // Initialize Workmanager for background tasks.
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider allows us to provide multiple objects to the widget tree.
    return MultiProvider(
      providers: [
        // The DateProvider is now available to the entire app.
        ChangeNotifierProvider(create: (_) => DateProvider()),
        // FinanceProvider now depends on DateProvider.
        ChangeNotifierProxyProvider<DateProvider, FinanceProvider>(
          create: (context) => FinanceProvider(
            dbHelper: DatabaseHelper.instance,
            dateProvider: Provider.of<DateProvider>(context, listen: false),
          ),
          update: (context, dateProvider, previousFinanceProvider) =>
              previousFinanceProvider ??
              FinanceProvider(
                dbHelper: DatabaseHelper.instance,
                dateProvider: dateProvider,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'دفتر التاجر',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // --- Arabic Language and RTL Support ---
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English for Latin digits
          Locale('ar', ''), // Arabic
        ],
        locale: const Locale('en', ''), // Force English locale for Latin digits
        home: const AppWrapper(),
      ),
    );
  }
}
