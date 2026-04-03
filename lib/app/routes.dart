import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/transaction_list_screen.dart';
import '../screens/add_edit_transaction_screen.dart';
import '../screens/goal_screen.dart';
import '../screens/insights_screen.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String transactions = '/transactions';
  static const String addEditTransaction = '/add_edit_transaction';
  static const String goal = '/goal';
  static const String insights = '/insights';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Custom fade + slide transition
    Widget Function(BuildContext) builder;
    switch (settings.name) {
      case dashboard:
        builder = (_) => const DashboardScreen();
        break;
      case transactions:
        builder = (_) => const TransactionListScreen();
        break;
      case addEditTransaction:
        final args = settings.arguments as Map?;
        builder = (_) => AddEditTransactionScreen(transaction: args?['transaction']);
        break;
      case goal:
        builder = (_) => const GoalScreen();
        break;
      case insights:
        builder = (_) => const InsightsScreen();
        break;
      default:
        builder = (_) => const DashboardScreen();
    }
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}