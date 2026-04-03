import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction.dart';
import '../data/repositories/finance_repository.dart';

final financeRepoProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

final transactionListProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier(ref.read(financeRepoProvider));
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final FinanceRepository _repository;
  String _searchQuery = '';
  TransactionType? _filterType;

  TransactionNotifier(this._repository) : super(_repository.getAllTransactions());

  void loadTransactions() {
    state = _repository.getAllTransactions();
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
    loadTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
    loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    loadTransactions();
  }
}