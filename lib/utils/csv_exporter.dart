import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../data/models/transaction.dart';
import 'formatters.dart';

class CSVExporter {
  static Future<void> exportTransactions(List<Transaction> transactions, String monthYear) async {
    if (transactions.isEmpty) {
      throw Exception('No transactions to export');
    }

    // Create CSV content
    StringBuffer csvBuffer = StringBuffer();

    // Header row
    csvBuffer.writeln('Date,Type,Category,Amount,Note,ID');

    // Data rows
    for (var t in transactions) {
      String date = formatDateForCSV(t.date);
      String type = t.type == TransactionType.income ? 'Income' : 'Expense';
      String amount = t.amount.toStringAsFixed(2);
      String note = t.note?.replaceAll(',', ';') ?? ''; // avoid CSV breaking
      String id = t.id;
      csvBuffer.writeln('$date,$type,${t.category},$amount,$note,$id');
    }

    // Save to temporary file
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/transactions_$monthYear.csv');
    await file.writeAsString(csvBuffer.toString());

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Here are my transactions for $monthYear',
      subject: 'Finance Companion Export',
    );
  }

  static String formatDateForCSV(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}