import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class GoalProgressRing extends StatelessWidget {
  final double progress;
  final double savedAmount;
  final double targetAmount;

  const GoalProgressRing({super.key, required this.progress, required this.savedAmount, required this.targetAmount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${formatCurrency(savedAmount)} / ${formatCurrency(targetAmount)}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (targetAmount > 0) Text('Need to save ${formatCurrency((targetAmount - savedAmount).clamp(0, double.infinity))} more'),
      ],
    );
  }
}