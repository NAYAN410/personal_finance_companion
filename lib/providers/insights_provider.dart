import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction.dart';
import 'transaction_provider.dart';

final insightsProvider = Provider<InsightsData>((ref) {
  final transactions = ref.watch(transactionListProvider);
  final repo = ref.read(financeRepoProvider);
  return InsightsData(
    totalIncome: repo.getTotalIncome(transactions),
    totalExpense: repo.getTotalExpense(transactions),
    balance: repo.getBalance(transactions),
    topCategory: _getTopCategory(repo.getExpenseByCategory(transactions)),
    weeklyChange: repo.getWeeklyComparison(transactions),
  );
});

class InsightsData {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final MapEntry<String, double>? topCategory;
  final double weeklyChange;

  InsightsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.topCategory,
    required this.weeklyChange,
  });
}

MapEntry<String, double>? _getTopCategory(Map<String, double> categories) {
  if (categories.isEmpty) return null;
  return categories.entries.reduce((a, b) => a.value > b.value ? a : b);
}