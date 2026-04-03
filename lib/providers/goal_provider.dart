import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/goal.dart';
import '../data/repositories/finance_repository.dart';
import 'transaction_provider.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, Goal?>((ref) {
  final repo = ref.read(financeRepoProvider);
  return GoalNotifier(repo, ref);
});

class GoalNotifier extends StateNotifier<Goal?> {
  final FinanceRepository _repository;
  final Ref _ref;

  GoalNotifier(this._repository, this._ref) : super(_repository.getGoal());

  Future<void> setGoal(double targetAmount, DateTime month) async {
    final goal = Goal(targetAmount: targetAmount, month: month);
    await _repository.saveGoal(goal);
    state = goal;
  }

  double getSavedAmount() {
    final transactions = _ref.read(transactionListProvider);
    final totalIncome = _repository.getTotalIncome(transactions);
    final totalExpense = _repository.getTotalExpense(transactions);
    return totalIncome - totalExpense;
  }

  double getProgress() {
    if (state == null) return 0.0;
    final saved = getSavedAmount();
    if (state!.targetAmount <= 0) return 0.0;
    return (saved / state!.targetAmount).clamp(0.0, 1.0);
  }
}