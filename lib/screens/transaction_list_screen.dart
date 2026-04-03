import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../data/models/transaction.dart';
import '../app/routes.dart';
import '../utils/formatters.dart';
import '../utils/csv_exporter.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _exportTransactions() async {
    final transactions = ref.read(transactionListProvider);
    final selectedMonth = ref.read(selectedMonthProvider);
    final monthYear = formatMonthYear(selectedMonth);

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    try {
      await CSVExporter.exportTransactions(transactions, monthYear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported $monthYear transactions')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionListProvider);
    final notifier = ref.read(transactionListProvider.notifier);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final availableMonths = ref.watch(availableMonthsProvider);
    final repo = ref.read(financeRepoProvider);

    final monthIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final monthExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final monthBalance = monthIncome - monthExpense;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          tooltip: 'Back',
        ),
        title: const Text('Transactions'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportTransactions,
            tooltip: 'Export CSV',
          ),
          PopupMenuButton<TransactionType?>(
            onSelected: (value) => notifier.setFilterType(value),
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(value: TransactionType.income, child: Text('Income')),
              const PopupMenuItem(value: TransactionType.expense, child: Text('Expense')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButton<DateTime>(
                    value: selectedMonth,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: availableMonths.map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(formatMonthYear(month)),
                      );
                    }).toList(),
                    onChanged: (newMonth) {
                      if (newMonth != null) {
                        ref.read(selectedMonthProvider.notifier).state = newMonth;
                        notifier.setSelectedMonth(newMonth);
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('Income', monthIncome, Colors.green),
                        Container(width: 1, height: 30, color: Colors.grey),
                        _summaryItem('Expense', monthExpense, Colors.red),
                        Container(width: 1, height: 30, color: Colors.grey),
                        _summaryItem('Balance', monthBalance, monthBalance >= 0 ? Colors.blue : Colors.orange),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by note...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: notifier.setSearchQuery,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: transactions.isEmpty
            ? _buildEmptyState(context, selectedMonth)
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Dismissible(
              key: Key(transaction.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                notifier.deleteTransaction(transaction.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${transaction.category} deleted'), duration: const Duration(seconds: 1)),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: TransactionTile(
                  transaction: transaction,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addEditTransaction,
                      arguments: {'transaction': transaction},
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addEditTransaction),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        elevation: 4,
        shape: StadiumBorder(),
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime selectedMonth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No transactions in ${formatMonthYear(selectedMonth)}', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addEditTransaction),
            icon: const Icon(Icons.add),
            label: const Text('Add one'),
            style: ElevatedButton.styleFrom(shape: StadiumBorder()),
          ),
        ],
      ),
    );
  }
}