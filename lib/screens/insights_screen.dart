import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/insights_provider.dart';
import '../utils/formatters.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    final insights = ref.watch(insightsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _buildInsightCard(
              title: 'Total Income',
              value: formatCurrency(insights.totalIncome),
              icon: Icons.trending_up,
              color: Colors.green,
              gradientColors: [Colors.green.shade400, Colors.green.shade700],
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              title: 'Total Expense',
              value: formatCurrency(insights.totalExpense),
              icon: Icons.trending_down,
              color: Colors.red,
              gradientColors: [Colors.red.shade400, Colors.red.shade700],
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              title: 'Balance',
              value: formatCurrency(insights.balance),
              icon: Icons.account_balance_wallet,
              color: insights.balance >= 0 ? Colors.blue : Colors.orange,
              gradientColors: insights.balance >= 0 ? [Colors.blue.shade400, Colors.blue.shade700] : [Colors.orange.shade400, Colors.orange.shade700],
            ),
            const SizedBox(height: 16),
            if (insights.topCategory != null)
              _buildInsightCard(
                title: 'Top Spending Category',
                value: '${insights.topCategory!.key}\n${formatCurrency(insights.topCategory!.value)}',
                icon: Icons.category,
                color: Colors.purple,
                gradientColors: [Colors.purple.shade400, Colors.purple.shade700],
                subtitle: 'Highest expense this month',
              ),
            const SizedBox(height: 16),
            _buildInsightCard(
              title: 'Weekly Spending Change',
              value: '${insights.weeklyChange.toStringAsFixed(1)}%',
              icon: insights.weeklyChange <= 0 ? Icons.arrow_downward : Icons.arrow_upward,
              color: insights.weeklyChange <= 0 ? Colors.green : Colors.red,
              gradientColors: insights.weeklyChange <= 0 ? [Colors.green.shade400, Colors.green.shade700] : [Colors.red.shade400, Colors.red.shade700],
              subtitle: insights.weeklyChange <= 0 ? 'Less than last week 🎉' : 'More than last week ⚠️',
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Add more transactions for detailed analysis.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}