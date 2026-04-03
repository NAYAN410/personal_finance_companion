import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../data/models/transaction.dart';
import '../utils/formatters.dart'; // for formatDate if needed

class SpendingChart extends ConsumerWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionListProvider);
    final chartData = _getLast7DaysData(transactions);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last 7 Days Spending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (chartData.values.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10, double.infinity),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: chartData.values.elementAt(index),
                          color: Colors.blue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text('₹${value.toInt()}'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Dynamic day names (actual dates)
                          final dayNames = chartData.keys.toList();
                          if (value.toInt() < dayNames.length) {
                            return Text(dayNames[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Returns a Map with key = day name (e.g., "Mon", "Tue", etc.) and value = expense amount
  // Order: from 6 days ago to today (left to right on chart)
  Map<String, double> _getLast7DaysData(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate last 7 days (from 6 days ago to today)
    List<DateTime> last7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    // Map day name to amount
    Map<String, double> result = {};
    for (var date in last7Days) {
      String dayName = _getDayName(date.weekday);
      result[dayName] = 0.0;
    }

    // Calculate expenses for each day
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
        final dayName = _getDayName(transactionDate.weekday);
        // Check if this date is within last 7 days
        if (transactionDate.isAfter(today.subtract(const Duration(days: 7))) &&
            transactionDate.isBefore(today.add(const Duration(days: 1)))) {
          result[dayName] = (result[dayName] ?? 0) + t.amount;
        }
      }
    }

    return result;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}