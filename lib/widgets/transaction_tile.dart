import 'package:flutter/material.dart';
import '../data/models/transaction.dart';
import '../utils/formatters.dart';
import 'category_icon.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CategoryIcon(category: transaction.category),
      title: Text(transaction.category),
      subtitle: Text(transaction.note ?? formatDate(transaction.date)),
      trailing: Text(
        formatCurrency(transaction.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}