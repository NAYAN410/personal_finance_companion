import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/goal.dart';

class FinanceRepository {
  static const String transactionBoxName = 'transactions';
  static const String goalBoxName = 'goalBox';

  // Transactions
  Future<void> addTransaction(Transaction transaction) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    await box.put(transaction.id, transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    await box.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    await box.delete(id);
  }

  List<Transaction> getAllTransactions() {
    final box = Hive.box<Transaction>(transactionBoxName);
    return box.values.toList();
  }

  // Goal
  Future<void> saveGoal(Goal goal) async {
    final box = Hive.box<Goal>(goalBoxName);
    await box.clear(); // only one goal at a time
    await box.add(goal);
  }

  Goal? getGoal() {
    final box = Hive.box<Goal>(goalBoxName);
    if (box.isEmpty) return null;
    return box.getAt(0);
  }

  // Statistics
  double getTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getBalance(List<Transaction> transactions) {
    return getTotalIncome(transactions) - getTotalExpense(transactions);
  }

  Map<String, double> getExpenseByCategory(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense);
    final map = <String, double>{};
    for (var t in expenses) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  double getWeeklyComparison(List<Transaction> transactions) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisWeekExpense = transactions
        .where((t) => t.type == TransactionType.expense && t.date.isAfter(thisWeekStart))
        .fold(0.0, (sum, t) => sum + t.amount);
    final lastWeekExpense = transactions
        .where((t) => t.type == TransactionType.expense && t.date.isAfter(lastWeekStart) && t.date.isBefore(thisWeekStart))
        .fold(0.0, (sum, t) => sum + t.amount);
    if (lastWeekExpense == 0) return 0;
    return ((thisWeekExpense - lastWeekExpense) / lastWeekExpense) * 100;
  }
}