import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/theme.dart';
import 'app/routes.dart';
import 'data/models/transaction.dart';  // imports transaction.g.dart
import 'data/models/goal.dart';          // imports goal.g.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters – order matters: enum first, then models
  Hive.registerAdapter(TransactionTypeAdapter());  // from transaction.g.dart
  Hive.registerAdapter(TransactionAdapter());      // from transaction.g.dart
  Hive.registerAdapter(GoalAdapter());             // from goal.g.dart

  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Goal>('goalBox');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Companion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.dashboard,
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}