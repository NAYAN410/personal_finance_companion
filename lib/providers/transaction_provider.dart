import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction.dart';
import '../data/repositories/finance_repository.dart';

final financeRepoProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

final transactionListProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier(ref.read(financeRepoProvider));
});

// Provider for selected month (format: DateTime with day=1)
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime(DateTime.now().year, DateTime.now().month);
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final FinanceRepository _repository;
  String _searchQuery = '';
  TransactionType? _filterType;
  DateTime? _selectedMonth;

  TransactionNotifier(this._repository) : super(_repository.getAllTransactions());

  // ✅ This method is called by RefreshIndicator
  void loadTransactions() {
    _applyFilters();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    _applyFilters();
  }

  void _applyFilters() {
    var all = _repository.getAllTransactions();

    // Filter by month if selected
    if (_selectedMonth != null) {
      all = all.where((t) =>
      t.date.year == _selectedMonth!.year &&
          t.date.month == _selectedMonth!.month).toList();
    }

    if (_searchQuery.isNotEmpty) {
      all = all.where((t) => t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false).toList();
    }
    if (_filterType != null) {
      all = all.where((t) => t.type == _filterType).toList();
    }
    state = all;
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _repository.addTransaction(transaction);
    _applyFilters();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
    _applyFilters();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    _applyFilters();
  }
}

// Helper: get all months that have transactions
final availableMonthsProvider = Provider<List<DateTime>>((ref) {
  final transactions = ref.read(transactionListProvider);
  final months = <DateTime>{};
  for (var t in transactions) {
    months.add(DateTime(t.date.year, t.date.month));
  }
  if (months.isEmpty) {
    return [DateTime(DateTime.now().year, DateTime.now().month)];
  }
  return months.toList()..sort((a, b) => b.compareTo(a)); // newest first
});