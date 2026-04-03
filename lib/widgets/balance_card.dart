import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({super.key, required this.balance, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text(formatCurrency(balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(children: [const Text('Income', style: TextStyle(color: Colors.white70)), Text(formatCurrency(income), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
                Column(children: [const Text('Expense', style: TextStyle(color: Colors.white70)), Text(formatCurrency(expense), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}