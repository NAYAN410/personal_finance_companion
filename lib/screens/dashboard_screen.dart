import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutQuad);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();

    // Sync selected month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMonth = ref.read(selectedMonthProvider);
      ref.read(transactionListProvider.notifier).setSelectedMonth(currentMonth);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionListProvider);
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
    final recent = transactions.reversed.take(5).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(context, isDark, selectedMonth, availableMonths),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.read(transactionListProvider.notifier).loadTransactions();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 110, bottom: 30),
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildPremiumBalanceCard(monthBalance, monthIncome, monthExpense),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSpendingInsightCard(transactions, repo, isDark),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildRecentTransactionsHeader(context, recent.length),
              ),
              recent.isEmpty
                  ? _buildEmptyState(context, selectedMonth)
                  : Column(
                children: recent
                    .map((t) => TransactionTile(transaction: t))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildPremiumFAB(context),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(BuildContext context, bool isDark,
      DateTime selectedMonth, List<DateTime> availableMonths) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.grey.shade900.withOpacity(0.7), Colors.grey.shade800.withOpacity(0.5)]
                    : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Finance Companion',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        // Month selector – modern pill style
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800.withOpacity(0.8) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButton<DateTime>(
            value: selectedMonth,
            underline: const SizedBox(),
            icon: const Icon(Icons.calendar_month, size: 18),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            items: availableMonths.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(formatMonthYear(month)),
              );
            }).toList(),
            onChanged: (newMonth) {
              if (newMonth != null) {
                HapticFeedback.selectionClick();
                ref.read(selectedMonthProvider.notifier).state = newMonth;
                ref.read(transactionListProvider.notifier).setSelectedMonth(newMonth);
              }
            },
          ),
        ),
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

  Widget _buildPremiumBalanceCard(double balance, double income, double expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade300.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNeumorphicStat(Icons.arrow_upward, 'Income', income, Colors.green),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildNeumorphicStat(Icons.arrow_downward, 'Expense', expense, Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicStat(IconData icon, String label, double amount, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
          _glassActionButton(context, Icons.add_card_rounded, 'Add', AppRoutes.addEditTransaction),
          _glassActionButton(context, Icons.list_alt_rounded, 'History', AppRoutes.transactions),
          _glassActionButton(context, Icons.insights_rounded, 'Insights', AppRoutes.insights),
        ],
      ),
    );
  }

  Widget _glassActionButton(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, route);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).primaryColor.withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingInsightCard(List<Transaction> transactions, FinanceRepository repo, bool isDark) {
    final weeklyChange = repo.getWeeklyComparison(transactions);
    final isPositive = weeklyChange > 0;
    final categoryMap = repo.getExpenseByCategory(transactions);
    final topCategory = categoryMap.entries.isEmpty
        ? null
        : categoryMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800.withOpacity(0.7) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Spending Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isPositive
                          ? LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600])
                          : LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${weeklyChange.toStringAsFixed(0)}% vs last week',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (topCategory != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Highest spend: ${topCategory.key}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        formatCurrency(topCategory.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: _buildGradientSparkline(transactions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientSparkline(List<Transaction> transactions) {
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
            gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)]),
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor.withOpacity(0.3), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
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
          const Text(
            '📋 Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (count > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, AppRoutes.transactions);
              },
              style: TextButton.styleFrom(
                shape: StadiumBorder(),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime selectedMonth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.6)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No transactions in ${formatMonthYear(selectedMonth)}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addEditTransaction),
            icon: const Icon(Icons.add),
            label: const Text('Add one'),
            style: ElevatedButton.styleFrom(
              shape: StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, AppRoutes.addEditTransaction);
      },
      icon: const Icon(Icons.add, size: 24),
      label: const Text('Add Transaction'),
      elevation: 6,
      shape: StadiumBorder(),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}