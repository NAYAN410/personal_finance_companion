import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../app/routes.dart';
import '../utils/formatters.dart';
import '../data/models/transaction.dart';
import '../data/repositories/finance_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionListProvider);
    final repo = ref.read(financeRepoProvider);
    final balance = repo.getBalance(transactions);
    final totalIncome = repo.getTotalIncome(transactions);
    final totalExpense = repo.getTotalExpense(transactions);
    final recent = transactions.reversed.take(5).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(context, isDark),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(transactionListProvider.notifier).loadTransactions(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 100, bottom: 30),
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBalanceHero(balance, totalIncome, totalExpense),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSpendingInsightCard(transactions, repo),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildRecentTransactionsHeader(context, recent.length),
              ),
              recent.isEmpty
                  ? _buildEmptyState(context)
                  : Column(children: recent.map((t) => TransactionTile(transaction: t)).toList()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingButton(context),
    );
  }

  // Clean, readable app bar – no blur
  PreferredSizeWidget _buildModernAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey.shade900.withOpacity(0.9) : Colors.white.withOpacity(0.9),
      title: const Text(
        'Finance Companion',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.insights),
          tooltip: 'Insights',
        ),
        IconButton(
          icon: const Icon(Icons.flag_rounded),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.goal),
          tooltip: 'Goal',
        ),
      ],
    );
  }

  Widget _buildBalanceHero(double balance, double income, double expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(balance),
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip(Icons.arrow_upward_rounded, 'Income', income, Colors.green.shade300),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildStatChip(Icons.arrow_downward_rounded, 'Expense', expense, Colors.red.shade300),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, double amount, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(context, Icons.add_card_rounded, 'Add', AppRoutes.addEditTransaction),
          _actionButton(context, Icons.list_alt_rounded, 'History', AppRoutes.transactions),
          _actionButton(context, Icons.insights_rounded, 'Insights', AppRoutes.insights),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSpendingInsightCard(List<Transaction> transactions, FinanceRepository repo) {
    final weeklyChange = repo.getWeeklyComparison(transactions);
    final isPositive = weeklyChange > 0;
    final categoryMap = repo.getExpenseByCategory(transactions);
    final topCategory = categoryMap.entries.isEmpty ? null : categoryMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💰 Spending Insight',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: isPositive ? Colors.red : Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${weeklyChange.toStringAsFixed(0)}% vs last week',
                          style: TextStyle(color: isPositive ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (topCategory != null)
                Row(
                  children: [
                    const Icon(Icons.category, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Highest spend: ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      topCategory.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(formatCurrency(topCategory.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: _buildMiniSparkline(transactions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSparkline(List<Transaction> transactions) {
    final last7Days = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dailyExpense = transactions
          .where((t) => t.type == TransactionType.expense &&
          t.date.day == date.day &&
          t.date.month == date.month &&
          t.date.year == date.year)
          .fold(0.0, (sum, t) => sum + t.amount);
      return dailyExpense;
    });
    final maxValue = last7Days.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: last7Days.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.1)),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxValue * 1.1,
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '📋 Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          if (count > 0)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.transactions),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addEditTransaction),
            icon: const Icon(Icons.add),
            label: const Text('Add your first transaction'),
            style: ElevatedButton.styleFrom(shape: StadiumBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.addEditTransaction),
      icon: const Icon(Icons.add, size: 24),
      label: const Text('Add'),
      elevation: 4,
      shape: StadiumBorder(),
    );
  }
}